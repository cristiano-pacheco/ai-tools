# Fx

Read for provider/interface bindings, module inclusion, publication, contributions
or hooks. A method/query change with verified unchanged wiring does not load Fx.

## Concrete construction and interface publication

Every application-owned struct constructor returns its concrete instance, usually
`*Type` or `(*Type, error)`; value constructors return `Type`. Bind an adapter
with `fx.Provide(fx.Annotate(NewImplementation, fx.As(new(port.Interface))))`.
Assert conformance beside the implementation. The pointer passed to `fx.As`
is a type token, not the adapter instance. Register the constructor once.

`fx.As` replaces the concrete result's exposed type. Add `fx.As(fx.Self())`
on the same provider only for an actual concrete consumer and a compatible Fx
version. Do not add an interface-returning application factory to perform a bind.
External framework factories keep their declared APIs; [Bricks](bricks.md) records
that boundary when choosing a framework package.

Provide use cases concretely and inject their concrete pointers into consumers
by default. Add [Usecase decorator](usecase-decorator.md) publication only when
explicitly requested or when modifying an existing decorated use case. Other
decorated operations in the project do not opt a new operation into that profile.

## Example: module composition

`internal/modules/order/fx.go`. This example publishes get/create application operations; its HTTP router exposes GET.
Constructors and assets live in their respective packages/recipes; they are
registered here at their owner, following the JBN composition approach.
The process provides `*database.ProjectDB`, Bricks validation/response/logger
dependencies and the real trusted `handler.ActorID` integration.

```go
package order

import (
	"example.com/project/internal/modules/order/http/chi/handler"
	"example.com/project/internal/modules/order/http/chi/router"
	"example.com/project/internal/modules/order/port"
	"example.com/project/internal/modules/order/repository"
	"example.com/project/internal/modules/order/usecase"
	"example.com/project/internal/modules/order/validator"
	brickschi "github.com/cristiano-pacheco/bricks/pkg/http/server/chi"
	"go.uber.org/fx"
)

var Module = fx.Module("order",
	fx.Provide(
		fx.Annotate(repository.NewOrderRepository, fx.As(new(port.OrderRepository))),
		fx.Annotate(validator.NewOrderAccessValidator, fx.As(new(port.OrderAccessValidator))),
		usecase.NewOrderGetUseCase,
		usecase.NewOrderCreateUseCase,
		handler.NewOrderHandler,
		fx.Annotate(router.NewOrderRouter,
			fx.As(new(brickschi.Route)), fx.ResultTags(`group:"routes"`)),
		fx.Annotate(provideMigrationFileSystem, fx.ResultTags(`group:"migration_filesystems"`)),
		fx.Annotate(provideLocaleFileSystem, fx.ResultTags(`group:"locale_filesystems"`)),
	),
)
```

Add only operations/adapters the requested behavior consumes. A module without
REST or persistence omits those providers and assets. [Fx contribution](fx-contribution.md)
loads only for names/groups, [Migration](migration.md) for schema/runner assets,
and [Locale](locale.md) for translation assets. Inspect unchanged constructors
without loading every referenced component guide.

## Example: binding construction proof

`internal/modules/order/fx_test.go`. An inert database wrapper satisfies the
constructor: this test performs no SQL and proves only direct use-case/port resolution.
Route proof must consume the registered HTTP path with real/stubbed
infrastructure appropriate to the guarantee, as [Integration bootstrap](integration-bootstrap.md)
explains. For an explicitly selected or existing decorated operation, composition
proof must also consume its decorated publication. Lazy providers not reached
by this invoke remain untested.

```go
package order_test

import (
	"testing"

	"example.com/project/internal/modules/order"
	"example.com/project/internal/modules/order/usecase"
	"example.com/project/internal/shared/database"
	bricksvalidator "github.com/cristiano-pacheco/bricks/pkg/validator"
	"go.uber.org/fx"
	"gorm.io/gorm"
)

func TestModuleBindings(t *testing.T) {
	var operation *usecase.OrderGetUseCase
	app := fx.New(fx.NopLogger, order.Module, bricksvalidator.Module,
		fx.Supply(&database.ProjectDB{DB: &gorm.DB{}}),
		fx.Invoke(func(uc *usecase.OrderGetUseCase) { operation = uc }),
	)
	if err := app.Err(); err != nil {
		t.Fatal(err)
	}
	if operation == nil {
		t.Fatal("use case was not constructed")
	}
}
```

`fx.ValidateApp` checks types without running constructors/hooks. Force the intended
consumer in both validation and construction proof; unused provider registration
establishes neither reachability nor external resource health. Select
[Runtime](runtime.md) when resource/lifecycle behavior changes and
[Bootstrap](bootstrap.md) when changing the process stack.

*Check:* concrete constructor, matching interface assertion/binding, one provider,
process inclusion, intended consumer reachability and separately proved runtime
behavior. No graph-only claim of database or HTTP readiness.
