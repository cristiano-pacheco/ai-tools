# HTTP data flow

Read when adding or changing an HTTP business entrypoint. [Data flow](data-flow.md) owns the shared operation contract. [HTTP handler](http-handler.md) owns transport responsibilities.

## 1. Separate registration from execution

At bootstrap, the process constructs the router and handler and registers the method and path. Registration does not execute the use case. At request time, the registered handler method is the business entrypoint.

For an existing order query:

```text
GET /api/v1/orders/42
  HTTP server and middleware reach HandleGetOrder.
  Middleware supplies trusted actor 7.
  The handler parses path 42 and builds OrderGetInput{ID: 42, ActorID: 7}.
  OrderGetUseCase.Execute validates input, loads state, and checks access.
  The operation returns OrderGetOutput{ID: 42, Status: "pending"}.
  The handler maps output into OrderGetResponse and renders HTTP 200.
```

GET does not need an invented request-body DTO. Its response DTO remains separate from application Output even when fields match. HTTP and Cobra call the same operation rather than maintaining separate policy.

## 2. Map at the boundary

These are fragments inside a handler after trusted identity and path validation:

```go
input := usecase.OrderGetInput{ID: id, ActorID: actorID}
output, err := handler.orderGetUseCase.Execute(request.Context(), input)
if err != nil {
    handler.errorHandler.Error(writer, err)
    return
}
result := mapper.ToOrderGetResponse(output)
```

`orderGetUseCase` is the injected concrete operation. `errorHandler` is the application's existing shared error renderer. Render `result` through the selected response API and stop after any write failure. This fragment does not define a second renderer or a framework-specific handler constructor.

For Bricks signatures, imports, bindings, and a complete handler over an existing operation, follow [Bricks handoff](bricks.md) to `recipes/existing-operation-http.md`. Use `recipes/http-flow.md` for a small complete new application. Load neither for an unchanged verified HTTP collaborator.

## 3. Handle a body-based operation

For creation, use [HTTP body](http-body.md): decode into `OrderCreateRequest`, combine only its allowed fields with trusted identity, invoke `OrderCreateUseCase.Execute`, then map to `OrderCreateResponse`.

```go
input := usecase.OrderCreateInput{ActorID: actorID, Notes: body.Notes}
```

Caller JSON must not overwrite the trusted actor. Body DTOs do not become operation input through aliases or embedding. Exposing creation requires its handler and POST registration. Providing the operation alone creates no endpoint.

## 4. Check where execution stops

| Situation | Required outcome |
| --- | --- |
| Missing trusted identity | Reject before the operation |
| Malformed or zero path ID | Reject before the operation |
| Malformed or unsupported body | Preserve the classified decode error; do not invoke policy |
| Valid JSON with invalid fields | Reject at use-case input validation |
| Missing record or denied access | Preserve the project's error and disclosure policy |
| Unexpected storage failure | Return safe generic HTTP failure without driver text |
| Response-write failure | Report once; do not render again or repeat the operation |

Done when one registered handler invokes one public operation with caller context, maps separate representations, and renders exactly one compatible outcome. Apply [Test policy](test-policy.md) to transport proof.
