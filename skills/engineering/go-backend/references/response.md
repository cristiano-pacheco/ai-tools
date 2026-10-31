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

## Verification

Apply [Test policy](test-policy.md): verify status, headers, envelopes, validation
details and safe error rendering through API end-to-end coverage. These library
contracts do not authorize a direct renderer suite in the consuming application.

*Check:* one success envelope or one error envelope, expected status/headers,
validation details, safe unknown errors, no shared error mutation and no second
write after a terminal response failure.
