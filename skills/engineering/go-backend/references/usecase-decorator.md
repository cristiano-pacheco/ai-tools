# Usecase decorator

Read when introducing/changing public operation publication or decorators.
A local business-rule edit with verified publication does not load this guide.
Default a new Bricks application to the JBN decorated profile; preserve an
established direct profile without migrating it as a side effect.

## Decorated profile

Register each concrete raw constructor once. The module publication provider
receives those instances and the Bricks factory, returning a named `fx.Out`
value with their public generic interfaces. HTTP, Cobra and cross-module callers
consume these interfaces. Raw integration tests construct the same use cases
when testing policy/persistence without decoration.

`internal/modules/order/decorate_usecase.go`.

```go
package order

import (
	"example.com/project/internal/modules/order/usecase"
	"github.com/cristiano-pacheco/bricks/pkg/ucdecorator"
	"go.uber.org/fx"
)

type decorateUseCasesIn struct {
	fx.In
	Factory     *ucdecorator.Factory
	OrderGet    *usecase.OrderGetUseCase
	OrderCreate *usecase.OrderCreateUseCase
}

type decorateUseCasesOut struct {
	fx.Out
	OrderGet    ucdecorator.UseCase[usecase.OrderGetInput, usecase.OrderGetOutput]
	OrderCreate ucdecorator.UseCase[usecase.OrderCreateInput, usecase.OrderCreateOutput]
}

func provideDecoratedUseCases(in decorateUseCasesIn) decorateUseCasesOut {
	return decorateUseCasesOut{
		OrderGet:    ucdecorator.Wrap(in.Factory, in.OrderGet),
		OrderCreate: ucdecorator.Wrap(in.Factory, in.OrderCreate),
	}
}
```

## Publication recipe

1. Implement the raw operation using [Use case](usecase.md): noun/action names,
   explicit input/output, input validation first, application policy and injected
   outbound ports. `NewOrderGetUseCase` and `NewOrderCreateUseCase` stay concrete.
2. Register both raw constructors once in the owning [Fx module](fx.md#example-module-composition).
   Add each operation to the one publication provider's input, output and `Wrap`
   call. Pass the raw instance to `Wrap` exactly once.
3. Consumers request `ucdecorator.UseCase[OperationInput, OperationOutput]` through
   constructor injection. [HTTP handler](http-handler.md) and [CLI](cli.md) show
   this contract. Cross-module application calls use that same published contract.
4. Register framework dependencies once at the process owner; [Server](server.md)
   shows the graph and base YAML. Resolve every new public specialization in
   composition proof. An unused lazy provider is not evidence of publication.
5. Verify raw behavior separately from public decoration. Read
   [Usecase decorator test](usecase-decorator-test.md) when adding/changing
   publication, flags, chain behavior or its proof; a local policy edit with
   verified publication does not load those tests.

One generic specialization identifies one public operation in Fx. Keep distinct
named input/output types for distinct operations, including empty wrappers.
Aliases do not create distinct types. Use an explicit named binding only for a
real compatibility requirement, with matching provider and consumer tags.

Publishing the raw constructor with `fx.As(new(ucdecorator.UseCase[...]))`
would expose the undecorated instance under the public key. Keep the raw pointer
and publication provider as separate graph nodes. A raw use case never injects
its own published specialization: that introduces a dependency cycle. A
cross-module call can inject another operation's specialization, keeping imports
and the runtime dependency graph acyclic.

## Framework contract

These observations match Bricks v0.1.21; verify the project's resolved version
before changing a chain. `ucdecorator.Wrap(factory, raw)` uses the factory's
loaded configuration; application code supplies neither invented option
arguments nor its own parallel generic decorator framework.

| Concern | Required behavior |
| --- | --- |
| Execution | logging -> metrics -> tracing -> translation -> raw operation, with each enabled layer wrapping the next |
| Invocation | One raw execution per public call; this chain adds no retries, transaction, authorization, validation or idempotency |
| Context | Forward caller context; tracing derives a child context. Preserve cancellation/values, not pointer identity. |
| Output/error | Preserve returned output and error, except the enabled error translator may reconstruct a coded error |
| Identity | Raw cause/pointer assertions and translated code/status assertions follow [Error](error.md) |
| Names | Raw `OrderGetUseCase` yields span/log name `OrderGetUseCase.Execute` and metric label `order_get` |
| Disabled chain | `enabled: false` returns the raw instance unchanged; individual flags apply only when enabled |
| Config defaults | The Fx loader decodes supplied YAML; it does not call `ucdecorator.DefaultConfig` to fill omitted flags. Declare every intended flag. |
| Dependencies | Factory construction still requires config, logger, metrics and translator when flags are disabled |
| Lifetime | Wrap once during composition; flags are captured at construction, not reloaded per request |

`debug_mode` adds diagnostic wrappers/logs; it is not another business operation
or a second metrics chain. Keep it off by default. Initialize tracing at the
shared process owner before traced execution. [Observability](observability.md)
owns global metrics/tracer lifetimes and adapter spans.

Generic operation logs, metrics, translation and the operation span stay outside
raw `Execute`. Keep business validation, permission, transaction scope and durable
success inside it. Adapters keep their own distinct I/O spans. Do not call `Wrap`
from handlers, commands, another decorator, or `Execute`; repeated wrapping
changes inferred names and duplicates observations.

The baseline chain does not recover panics. Its metrics layer records only normal
returns, and the logging defer can observe a nil error during panic unwinding.
Do not promise accurate panic failure metrics/logs from these decorators;
recovery belongs to the actual process/transport boundary.

*Check:* raw/public keys are distinct, each raw constructor and Wrap is registered
once, all public consumers resolve, configured effects occur once, disabled
behavior is preserved, and code/status/cancellation contracts are proved at the
boundary claimed. Static Fx validation alone does not prove execution effects.

## Direct profile

When the project deliberately publishes concrete use cases, callers receive
`*usecase.OrderGetUseCase` and Fx provides the raw constructor directly. Register
neither a second public interface binding nor a decorator chain solely to match
this example. Constructor return types remain concrete in both profiles.
