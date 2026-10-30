# Bricks request

Read when choosing/changing JSON decoding, content type, body limits or decode
errors. Use `github.com/cristiano-pacheco/bricks/pkg/http/request` in the HTTP
entrypoint. Application field validation stays in the use case.
These contracts match v0.1.21; check the resolved version before relying on them.

## API and destination

| API | Contract |
| --- | --- |
| `ReadJSON(w, r, dst)` | Uses `DefaultMaxBodySize`, 1,048,576 bytes |
| `ReadJSONWithMaxSize(w, r, dst, maxBytes)` | Uses the endpoint's explicit positive read limit |
| Destination | Pointer to an HTTP-owned request DTO; invalid destinations can panic |
| Return | `error`; helper does not render a response or invoke the operation |

For an object body, decode into a DTO pointer through `&body` and reject a nil
result. JSON `null` decodes without error; the handler must reject it when the
endpoint requires an object. [HTTP body](http-body.md) has the complete handler.
PATCH omission/null/value semantics require a presence type.

## Decode error contract

Return parser errors unchanged to `response.ErrorHandler.Error(w, err)`.
The parser already creates `*errs.Error` with the proper code/status.
Replacing them all with a generic bad-request error loses 413 and 415 semantics.
Decode failures occur before use-case execution and keep framework messages;
they also bypass decorators when the operation is explicitly decorated. If the
API localizes them, apply translation at its shared HTTP error boundary.

| Input | Code | HTTP status |
| --- | --- | --- |
| Malformed JSON, empty body, incompatible field type, unknown field | `BAD_REQUEST` | 400 |
| A second JSON value detected by the helper | `BAD_REQUEST` | 400 |
| Present non-JSON Content-Type | `UNSUPPORTED_MEDIA_TYPE` | 415 |
| Read exceeds the configured bound | `REQUEST_ENTITY_TOO_LARGE` | 413 |
| Valid JSON with invalid application fields | Use-case validation, not parser rejection | 422 through the response renderer |

The baseline permits an absent Content-Type. A present value must be
`application/json`, optionally with parameters; comparison is case-sensitive.
A stricter API must check its additional policy at the shared HTTP boundary.
Neither content-type checking nor decoding establishes authentication or CSRF
protection. Trusted identity comes from middleware.

## Limits of the baseline parser

The helper uses `http.MaxBytesReader`, `DisallowUnknownFields` and a post-decode
`Decoder.More` check. That check is not an EOF assertion. A trailing closing `]`
or `}` can pass, and unread trailing bytes may not consume the read bound.
When the API requires whole-body validation, adapt the shared request helper
and test those inputs. Do not claim the stock helper enforces that contract.

## Executable contract examples

`internal/shared/http/request_test.go`. These tests distinguish library behavior
from endpoint policy. The closing-delimiter case records a library limitation;
it is not an instruction to accept that payload in a stricter API.

```go
package http_test

import (
	"errors"
	"net/http/httptest"
	"strings"
	"testing"

	brickserrs "github.com/cristiano-pacheco/bricks/pkg/errs"
	"github.com/cristiano-pacheco/bricks/pkg/http/request"
)

func TestBricksRequestContract(t *testing.T) {
	cases := []struct {
		name, body, contentType, code string
		status                        int
		null                          bool
	}{
		{name: "object", body: `{}`, contentType: "application/json"},
		{name: "missing content type", body: `{}`},
		{name: "charset", body: `{}`, contentType: "application/json; charset=utf-8"},
		{name: "null needs endpoint rejection", body: `null`, null: true},
		{name: "empty", body: ``, code: "BAD_REQUEST", status: 400},
		{name: "malformed", body: `{`, code: "BAD_REQUEST", status: 400},
		{name: "wrong field type", body: `{"notes":1}`, code: "BAD_REQUEST", status: 400},
		{name: "unknown field", body: `{"owner_id":7}`, code: "BAD_REQUEST", status: 400},
		{name: "second value", body: `{} {}`, code: "BAD_REQUEST", status: 400},
		{name: "wrong media", body: `{}`, contentType: "text/plain", code: "UNSUPPORTED_MEDIA_TYPE", status: 415},
		{name: "oversize", body: `{"notes":"` + strings.Repeat("a", 128) + `"}`, code: "REQUEST_ENTITY_TOO_LARGE", status: 413},
		{name: "baseline trailing delimiter limitation", body: `{} ]`},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			r := httptest.NewRequest("POST", "/orders", strings.NewReader(tc.body))
			if tc.contentType != "" {
				r.Header.Set("Content-Type", tc.contentType)
			}
			w := httptest.NewRecorder()
			var body *struct {
				Notes *string `json:"notes"`
			}
			err := request.ReadJSONWithMaxSize(w, r, &body, 64)
			if tc.code != "" {
				var coded *brickserrs.Error
				if !errors.As(err, &coded) || coded.Code != tc.code || coded.Status != tc.status {
					t.Fatalf("expected %s/%d, got %v", tc.code, tc.status, err)
				}
				return
			}
			if err != nil {
				t.Fatal(err)
			}
			if (body == nil) != tc.null {
				t.Fatalf("unexpected null body: %#v", body)
			}
		})
	}
}
```

*Check:* pointer destination, object/null policy, read bound, unknown fields,
parser code/status preservation and no operation call after a decode failure.
[Response](response.md) owns rendering; [Error](error.md) owns business codes.
