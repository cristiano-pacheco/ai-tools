# Fx

Read for provider bindings, module inclusion, publication, contributions, or hooks. A method change with verified unchanged wiring does not load this guide.

## 1. Keep constructors concrete

Application struct constructors return `*Type`, `Type`, or the same concrete result with an error. Assert interface conformance beside the adapter. Bind the consumer-owned port at composition:

```go
fx.Provide(fx.Annotate(
    repository.NewOrderRepository,
    fx.As(new(port.OrderRepository)),
))
```

The pointer passed to `fx.As` is a type token, not an adapter instance. `fx.As` replaces the exposed result type. Add `fx.As(fx.Self())` on the same provider only when a real consumer also needs the concrete value and the installed Fx version supports it. Register the constructor once.

External factories keep their declared signatures. A bridge to a framework-provided interface is not permission to make application constructors return interfaces.

## Example: module composition

`internal/modules/order/fx.go`:

```go
package order

import (
    "example.com/project/internal/modules/order/port"
    "example.com/project/internal/modules/order/repository"
    "example.com/project/internal/modules/order/usecase"
    "example.com/project/internal/modules/order/validator"
    "go.uber.org/fx"
)

var Module = fx.Module("order",
    fx.Provide(
        fx.Annotate(repository.NewOrderRepository, fx.As(new(port.OrderRepository))),
        fx.Annotate(validator.NewOrderAccessValidator, fx.As(new(port.OrderAccessValidator))),
        usecase.NewOrderGetUseCase,
        usecase.NewOrderCreateUseCase,
    ),
)
```

The process supplies the shared database wrapper and the existing input validator under the `port.InputValidator` contract used by the example operations. The module registers only its owned components. Add handlers and framework contributions only when that transport or asset is required. This fragment does not claim to expose HTTP by itself.

Provide use cases concretely by default. Select [Usecase decorator](usecase-decorator.md) only for requested decoration or changes to an existing decorated operation.

## 2. Register contributions at their owner

Use [Fx contribution](fx-contribution.md) for names and groups. Use the server's actual route interface and asset contracts rather than creating parallel registries. For Bricks-specific providers, bindings, groups, or forcing invokes, follow [Bricks handoff](bricks.md) to the selected framework guide.

Read unchanged constructor signatures without loading every collaborator's recipe.

## 3. Prove reachability and runtime separately

`fx.ValidateApp` checks types without running constructors or hooks. Force the intended consumer when validating its dependencies. Construction proof must also consume it because providers are lazy. Neither check establishes a live database or listening HTTP server.

For public-operation integration proof, use the production module and real controlled adapters under [Integration bootstrap](integration-bootstrap.md). For API transport proof, use the actual listening application under [Test policy](test-policy.md). A decorated operation's publication must be consumed when decoration is the claim.

Done when each instance has one provider, bindings match consumer contracts, required consumers are reachable, and changed runtime behavior has separate execution evidence.
