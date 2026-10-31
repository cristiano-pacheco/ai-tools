# REST routing

Select the changed HTTP contract. Read linked implementation guides only for
components being changed or behavior that needs verification.

| Contract | Reference |
| --- | --- |
| Wire fields/tags, omission/null/zero and DTO ownership | [HTTP DTO](http-dto.md) |
| Entrypoint, operation invocation and mapping | [HTTP handler](http-handler.md) |
| JSON parser, media type, read limit and decode errors | [Request](request.md) |
| Success/error envelope, validation details, status/headers and write failures | [Response](response.md) |
| Body-based operation mapping | [HTTP body](http-body.md) |
| Method/path, route groups and middleware attachment | [HTTP router](http-router.md) |
| Middleware context, rejection and execution order | [HTTP middleware](http-middleware.md) |
| Collection pages, filters, order and metadata | [Pagination](pagination.md) |
| HTTP/application conversion | [Mapper](mapper.md) |

A new endpoint needs its handler, route and wire DTOs. Reuse an existing public
operation when it supplies the required behavior. Add [Use case](usecase.md)
for changed policy/contracts, [Error](error.md) for new business classifications
and [Fx](fx.md) for changed providers or bindings. A SQL-only correction needs no
HTTP changes. Use [Routing](routing.md) for other application responsibilities.

Update API docs/generation when required by the public change or project rules.
Select coverage through [Test policy](test-policy.md) before adding tests.
Verify changed method/path, decoding, middleware, status and payload through
API end-to-end coverage. Business behavior belongs in usecase/service integration
coverage; pure mapping follows the unit-test policy. This recipe does not
authorize direct handler, router or middleware suites.
