# Fx contribution

Read for named values, grouped routes, migrations or locales. [Fx](fx.md) owns
constructor/binding rules. Value group ordering is unspecified; it cannot express
migration dependencies or middleware order.

## Named primary/replica alternative

`internal/modules/order/read_write_fx.go`. Replace the ordinary repository
registration in the owner's `fx.go` with this option only for a deployment that
actually publishes `*gorm.DB` named `read` and `write`. Do not include both
registrations. The process owns the two handles and their lifecycles.

```go
package order

import (
	"example.com/project/internal/modules/order/port"
	"example.com/project/internal/modules/order/repository"
	"go.uber.org/fx"
)

var ReadWriteRepository = fx.Provide(fx.Annotate(
	repository.NewReadWriteOrderRepository,
	fx.ParamTags(`name:"read"`, `name:"write"`),
	fx.As(new(port.OrderRepository)),
))
```

## Grouped contributions

Use the selected framework's real contribution types. The provider's result
tag must match the consumer's `fx.In` field tag and element type. A framework
may prescribe a group name, or the application may choose it. Verify which
contract applies rather than assuming every group is framework-owned.

Follow [Bricks handoff](bricks.md) only when a Bricks route, SQL filesystem,
or locale contribution needs implementation. Its selected guide supplies the
actual provider and consumer. Keep application ownership in [HTTP router](http-router.md),
[Migration](migration.md), and [Locale](locale.md). Do not create a parallel
route interface or registry to avoid the framework's existing contract.

For a singular named dependency, use matching `fx.ParamTags` or an `fx.In`
field with the same name. Multiple interfaces on one instance use multiple
`fx.As` annotations on that one constructor, optionally `fx.As(fx.Self())`
when a real consumer also needs the concrete instance.

*Check:* exact result/parameter tags, one registration per instance, actual
consumer reachability and no reliance on group order for dependent effects.
