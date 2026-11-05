# HTTP body

Read when an endpoint accepts JSON. [Request](request.md) owns the application's syntax and limits policy. [Response](response.md) owns its published wire contract.

1. Resolve trusted identity from the existing middleware context. Keep it separate from caller-controlled JSON.
2. Decode into an HTTP-owned DTO with the selected body limit and null policy. Return the parser's classified error through the shared renderer. Do not invoke policy after a decode failure.
3. Build explicit application input. For creation, map allowed fields rather than embedding the request:

```go
input := usecase.OrderCreateInput{
    ActorID: actorID,
    Notes: body.Notes,
}
```

4. Invoke the concrete public use case once with the request context. It owns field validation and business decisions. Preserve an already decorated consumer only when that is the selected operation's contract.
5. Map output to an HTTP response DTO and render the promised creation status. Report a terminal write failure without attempting a second response.

For Bricks decoder and renderer code, follow [Bricks handoff](bricks.md). Its `recipes/http-flow.md` includes a complete body-based application with separate wire and operation values. `references/http/request/usage.md` supplies the actual limit, null, content-type, and trailing-data guarantees.

Done when identity cannot come from the body, malformed input cannot reach policy, and the operation's result maps to one compatible response. Verify transport through [Test policy](test-policy.md).
