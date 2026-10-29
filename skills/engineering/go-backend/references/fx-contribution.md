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

Use the framework's existing types and groups:

| Contribution | Concrete provider result / Fx exposure | Real consumer |
| --- | --- | --- |
| HTTP route | `*router.OrderRouter` -> `brickschi.Route`, `group:"routes"` | `brickschi.Module` collects `[]Route` and invokes `Setup(*Server)` |
| SQL assets | `migration.FileSystem`, `group:"migration_filesystems"` | Application migration runner receives the tagged slice |
| Locale assets | `locale.FileSystem`, `group:"locale_filesystems"` | `i18n.Module` collects the slice |

There is no application-owned parallel `Route` interface or second registry.
[HTTP router](http-router.md) implements the actual framework interface;
[Migration](migration.md) and [Locale](locale.md) define concrete asset providers.
The module's [Fx example](fx.md#example-module-composition) registers them.

For a singular named dependency, use matching `fx.ParamTags` or an `fx.In`
field with the same name. Multiple interfaces on one instance use multiple
`fx.As` annotations on that one constructor, optionally `fx.As(fx.Self())`
when a real consumer also needs the concrete instance.

*Check:* exact result/parameter tags, one registration per instance, actual
consumer reachability and no reliance on group order for dependent effects.
