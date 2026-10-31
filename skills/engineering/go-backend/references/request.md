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

## Verification

Apply [Test policy](test-policy.md): verify endpoint decoding through API
end-to-end coverage. Use the input cases and statuses above, including null,
trailing delimiters and unread bytes when strict whole-body validation is
required. These library contracts do not authorize a direct parser suite in
the consuming application.

*Check:* pointer destination, object/null policy, read bound, unknown fields,
parser code/status preservation and no operation call after a decode failure.
[Response](response.md) owns rendering; [Error](error.md) owns business codes.
