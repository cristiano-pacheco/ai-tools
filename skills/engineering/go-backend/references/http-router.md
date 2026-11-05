# HTTP router

Own method/path registration, route groups, and middleware attachment in `http/chi/router/<resource>_router.go`. Keep policy, mapping, validation, and I/O out. Its constructor returns the concrete router pointer.

## 1. Preserve public routes

Inspect the closest route and its published contract. Default new routes to versioned plural resource paths under `/api/v1`, with `{id}` and explicit owned sub-resources. Use GET for retrieval, POST for creation or actions, PUT for replacement, PATCH for partial mutation, and DELETE for removal. Preserve established semantics.

## 2. Register handler methods

Keep middleware order visible. Attach authentication to the smallest required group. A focused Chi registration fragment is:

```go
router.Get("/api/v1/orders/{id}", orderHandler.HandleGetOrder)
```

This registers a method. It does not execute application policy. Use the existing server's route contribution rather than creating another registry or interface.

## 3. Publish at composition

For Bricks `Route`, `Setup`, group tags, and server collection, follow [Bricks handoff](bricks.md) to its Chi guide. Bind the concrete application router through Fx. Adding a path to an already constructed router does not require changing its provider graph.

Read [Fx contribution](fx-contribution.md) only when bindings or tags change. Read [Bootstrap](bootstrap.md) only when the process changes.

## 4. Verify the actual API

Apply [Test policy](test-policy.md). Test changed paths, middleware scope, serialization, and statuses through the application's listening server. A registered router or isolated handler remains a component test and is excluded by default.

Done when routes reach the intended handlers, middleware has the required scope, the process includes the contribution, and transport proof uses the allowed boundary.
