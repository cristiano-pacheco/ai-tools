# HTTP router

Own method/path registration, route groups, and middleware attachment in
`http/chi/router/<resource>_router.go`. Keep policy, mapping, validation, storage,
and provider behavior out. Constructor returns the concrete router pointer.

## Recipe: register a route

1. Inspect the closest route and published contract. Default to versioned plural
   resource paths under `/api/v1`, with `{id}` and explicit owned sub-resources.
   Use GET for retrieval, POST for creation/action, PUT for replacement, PATCH
   for partial mutation, DELETE for removal; preserve established public semantics.
2. Register the handler's `Handle...` method directly. Keep group scope and
   middleware order visible. Attach auth to the smallest required group.
3. Publish a newly constructed router through the module's Fx contribution
   consumed by its server. [Fx contribution](fx-contribution.md) has grouped-contribution examples. Adding
   a path to an already constructed router does not change the provider graph.
4. Extend the registered-router proof for method/path, middleware scope, handler
   invocation, response serialization, and error status. An unregistered handler
   test cannot prove runtime route discovery.

## Example: router

`internal/modules/order/http/chi/router/order_router.go`. Attach required auth
middleware through the established route group; the handler also rejects a
missing trusted identity.

```go
package router

import (
	"example.com/project/internal/modules/order/http/chi/handler"
	brickschi "github.com/cristiano-pacheco/bricks/pkg/http/server/chi"
)

type OrderRouter struct {
	handler *handler.OrderHandler
}

var _ brickschi.Route = (*OrderRouter)(nil)

func NewOrderRouter(handler *handler.OrderHandler) *OrderRouter {
	return &OrderRouter{handler: handler}
}

func (r *OrderRouter) Setup(server *brickschi.Server) {
	server.Router().Get("/api/v1/orders/{id}", r.handler.HandleGetOrder)
}
```

*Check:* direct registration, published method/path, correct middleware group,
actual inclusion in the process graph, and no application logic in router code.

Publish with `fx.As(new(brickschi.Route))` and `group:"routes"`; the Bricks
server owns collection and setup. Keep authentication order inside the route
group, independently of Fx group enumeration. Read [Bootstrap](bootstrap.md)
only when server/process composition changes.
