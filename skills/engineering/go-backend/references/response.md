# Bricks response

Read when choosing/changing success envelopes, statuses/headers, error rendering
or response-write handling. Use `github.com/cristiano-pacheco/bricks/pkg/http/response`.
These contracts match v0.1.21; preserve an existing API's published wire format.

## Success contract

| API | Wire contract | Default use |
| --- | --- | --- |
| `JSON(w, status, dto, headers)` | `{"data": dto}` | JSON operation result |
| `JSONRaw(w, status, dto, headers)` | Encodes dto without envelope | Existing raw format or a protocol that requires it |
| `NoContent(w)` | 204, no body | Bodyless success |

Map operation Output to an HTTP-owned response DTO before rendering. Pass the
DTO directly to `JSON`; wrapping it in `data` first creates a double envelope.
Use 200 for retrieval, 201 for creation and 204 for the documented bodyless case.
Action endpoints keep their published semantics. Pass `nil` for absent headers;
set Location through the header argument when the create contract promises it.

`JSON` and `JSONRaw` marshal before writing headers, set application/json and
Content-Length, add supplied headers, then write status/body. Reserve Content-Type
and Content-Length for the helper; the header argument uses Add, not replacement.
They return marshal/write errors. A write may have committed the response, so
log the failure and stop; do not call the error renderer or execute again.
The handler examples use JSON-safe DTO fields and this terminal-error policy.

## Error contract

Inject `response.ErrorHandler`. Call `Error(w, err)` once and return from the
handler. It returns no value; serialization/write failures are logged internally.
Do not combine it with `http.Error`, direct JSON encoding or another envelope.

The renderer checks error chains in this order:

| Match | Status and payload |
| --- | --- |
| `validator.ValidationErrors` through `errors.As` | 422, `INVALID_ARGUMENT`, message `request has invalid fields`, field details |
| `*errs.Error` through `errors.As` | Its status, code, safe message and optional details |
| Any other error | 500, code `internal_server_error`, message `Internal server error` |

Errors use `{"error":{"code":"...","message":"...","details":[...]}}`.
Details contain field/message pairs and are omitted when absent. Status and
OriginalError are not JSON fields. Preserve code spelling/case, including the
framework's lowercase `internal_server_error`. Unexpected technical text stays off the wire.
Known business errors must already contain safe text; the renderer publishes it.

Validation details derive field names from Go fields using camel-to-snake
conversion, not JSON tags. Return validation failures intact and test names
against the API contract. The framework validator supplies English field
translations; i18n catalog translation does not automatically localize those.

Give catalog errors nonzero statuses and keep shared values immutable. The
baseline renderer assigns 500 to a typed error whose status is zero, mutating it.
Create fresh typed errors for request-specific details. [Error](error.md) owns
the catalog and cause/identity contracts; [Locale](locale.md) owns translated text.

The renderer logs its own marshal/write failures, not the original unknown
application error. In the default direct-use-case profile, define or preserve
that reporting owner rather than assuming every rendered 500 has been logged.
An explicitly selected or existing decorated operation may delegate reporting
to its logging layer; verify that layer is enabled and reached.

## Composition

Register `response.Module`, `validator.Module` and the logger owner once in the
process graph. `response.Module` binds `NewErrorHandler`'s concrete
`*ErrorHandlerImpl` to `response.ErrorHandler`. Handlers consume the interface.
Reuse that instance; do not construct a renderer for each request.
[Server](server.md) has the complete graph, [HTTP data flow](data-flow-http.md)
has the handler, and [HTTP body](http-body.md) connects parser errors to it.

## Executable contract examples

`internal/shared/http/response_test.go`. The renderer tests use the real validator.
A nil logger is sufficient here because recorder writes succeed; production uses
the process-owned logger.

```go
package http_test

import (
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	brickserrs "github.com/cristiano-pacheco/bricks/pkg/errs"
	"github.com/cristiano-pacheco/bricks/pkg/http/request"
	"github.com/cristiano-pacheco/bricks/pkg/http/response"
	"github.com/cristiano-pacheco/bricks/pkg/validator"
)

func TestBricksSuccessResponse(t *testing.T) {
	w := httptest.NewRecorder()
	value := struct {
		ID uint64 `json:"id"`
	}{ID: 42}
	headers := http.Header{"Location": {"/api/v1/orders/42"}}
	if err := response.JSON(w, http.StatusCreated, value, headers); err != nil {
		t.Fatal(err)
	}
	if w.Code != 201 || w.Body.String() != `{"data":{"id":42}}` || w.Header().Get("Location") != "/api/v1/orders/42" {
		t.Fatalf("unexpected response: %d %s", w.Code, w.Body.String())
	}
	if w.Header().Get("Content-Type") != "application/json" {
		t.Fatal("expected JSON")
	}
	empty := httptest.NewRecorder()
	response.NoContent(empty)
	if empty.Code != 204 || empty.Body.Len() != 0 {
		t.Fatal("expected bodyless 204")
	}
}

func TestBricksErrorResponse(t *testing.T) {
	v, err := validator.New()
	if err != nil {
		t.Fatal(err)
	}
	renderer := response.NewErrorHandler(v, nil)
	invalid := struct {
		Quantity int `validate:"gt=0"`
	}{}
	validationError := v.Validate(invalid)
	if validationError == nil {
		t.Fatal("expected validation failure")
	}
	cases := []struct {
		name   string
		err    error
		status int
		code   string
	}{
		{"validation", validationError, 422, "INVALID_ARGUMENT"},
		{"wrapped catalog", fmt.Errorf("lookup: %w", brickserrs.New("ORDER_02", "Order not found", 404, nil)), 404, "ORDER_02"},
		{"unknown", errors.New("private driver detail"), 500, "internal_server_error"},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			w := httptest.NewRecorder()
			renderer.Error(w, tc.err)
			var body struct {
				Error struct {
					Code    string              `json:"code"`
					Message string              `json:"message"`
					Details []brickserrs.Detail `json:"details"`
				} `json:"error"`
			}
			if err := json.Unmarshal(w.Body.Bytes(), &body); err != nil {
				t.Fatal(err)
			}
			if w.Code != tc.status || body.Error.Code != tc.code {
				t.Fatalf("unexpected error response: %d %#v", w.Code, body)
			}
			if strings.Contains(w.Body.String(), "private driver detail") {
				t.Fatal("technical error leaked")
			}
			if tc.name == "validation" && (len(body.Error.Details) != 1 || body.Error.Details[0].Field != "quantity") {
				t.Fatalf("unexpected field details: %#v", body.Error.Details)
			}
		})
	}
}
func TestDecodeErrorKeepsHTTPStatus(t *testing.T) {
	v, err := validator.New()
	if err != nil {
		t.Fatal(err)
	}
	renderer := response.NewErrorHandler(v, nil)
	for _, tc := range []struct {
		media, body, code string
		status            int
	}{
		{"text/plain", `{}`, "UNSUPPORTED_MEDIA_TYPE", 415},
		{"application/json", `{"notes":"` + strings.Repeat("a", 128) + `"}`, "REQUEST_ENTITY_TOO_LARGE", 413},
	} {
		t.Run(tc.code, func(t *testing.T) {
			r := httptest.NewRequest("POST", "/orders", strings.NewReader(tc.body))
			r.Header.Set("Content-Type", tc.media)
			w := httptest.NewRecorder()
			var body struct {
				Notes string `json:"notes"`
			}
			decodeError := request.ReadJSONWithMaxSize(w, r, &body, 16)
			if decodeError == nil {
				t.Fatal("expected decode rejection")
			}
			renderer.Error(w, decodeError)
			var result struct {
				Error struct {
					Code string `json:"code"`
				} `json:"error"`
			}
			if err := json.Unmarshal(w.Body.Bytes(), &result); err != nil {
				t.Fatal(err)
			}
			if w.Code != tc.status || result.Error.Code != tc.code {
				t.Fatalf("unexpected decode response: %d %s", w.Code, w.Body.String())
			}
		})
	}
}
```

*Check:* one success envelope or one error envelope, expected status/headers,
validation details, safe unknown errors, no shared error mutation and no second
write after a terminal response failure.
