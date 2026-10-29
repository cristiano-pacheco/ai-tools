# HTTP handler

A handler owns transport syntax, trusted identity, one public operation call,
wire mapping and rendering. Use Bricks `http/response`, its `ErrorHandler`, and
`logger.Logger`; the process provides their Fx modules once. Business policy,
repositories, transactions, cache and external providers stay behind the use case.

## Recipe

1. Create a concrete handler in `http/chi/handler/<resource>_handler.go`.
   Inject `ucdecorator.UseCase[Input, Output]` for the default decorated profile.
   Preserve a documented direct profile in an existing project.
2. Use `r.Context()`. Decode path/query/body into HTTP-owned DTOs, rejecting
   malformed/overflowed identifiers before invoking policy. Trusted actor/tenant
   comes from middleware, independently of caller-controlled fields.
3. Call one public operation and map Output to an HTTP DTO. Use the
   [Response](response.md) success envelope and error renderer. Return after
   errors; treat response-write failures as terminal.

## Implementation example

[HTTP data flow](data-flow-http.md) owns the complete `OrderHandler` example and
its request/Input/Output/response trace. Read it when implementing/changing the
entrypoint or clarifying mapping; its GET and body-based branches are explicit.

Select [HTTP DTO](http-dto.md) for wire changes, [Mapper](mapper.md) for conversion,
and [HTTP body](http-body.md) for body/media/limit behavior. Inspect an unchanged
operation signature without loading its implementation recipe.

*Check:* trusted context, HTTP-owned values, one application invocation, exact
status/envelope, safe errors and no second response after a write failure.
