# Use case

A usecase is the public application entrypoint for a business operation and owns
its policy and orchestration. HTTP/Cobra decode and render around this operation;
they do not bypass it to invoke a service, repository, or provider directly.
Apply [Component classification](component-classification.md) when deciding
whether behavior is operation-local or an independently justified collaborator.

## Naming contract

Create one operation per `internal/modules/<module>/usecase/<noun>_<action>_usecase.go`.
Use noun before action consistently:

| Artifact | Required example |
| --- | --- |
| File | `order_get_usecase.go` |
| Type | `OrderGetUseCase` |
| Input | `OrderGetInput` |
| Output | `OrderGetOutput` |
| Constructor | `NewOrderGetUseCase` |
| Public method | `Execute` |

For confirmation, the corresponding names are `order_confirm_usecase.go`,
`OrderConfirmUseCase`, `OrderConfirmInput`, and `OrderConfirmOutput`.

## Execution profile

Use a plain concrete use case by default. Register `New<Name>UseCase` once in
Fx and inject `*usecase.<Name>UseCase` into HTTP, Cobra and application callers;
invoke `Execute` directly. No decorator interface, `Wrap`, publication provider,
factory module or decorator configuration is required.

Use decorators only when explicitly requested, or preserve them when changing
an existing use case that is already decorated. A decorated neighboring operation,
installed framework package or existing application factory does not opt a new
use case in. Do not migrate existing decorated operations to direct execution
as a side effect of another change. Read [Usecase decorator](usecase-decorator.md)
only for opted-in decoration/publication work; verified unchanged wiring does
not require loading that guide for a local policy edit.

## Recipe: implement an operation

1. Declare input, output, use-case struct, constructor, `Execute`, then unexported
   receiver methods for operation-local orchestration. Define explicit named
   input/output structs even when empty. Shared values use named fields, not
   aliases or embedded operation contracts.
2. Put simple shape constraints in input `validate` tags. Inject the established
   input validator and validate the complete input as the first action of `Execute`.
   Use Bricks `validator.Validator.Validate`; provide `validator.Module` once at
   the process owner. Named business rules retain their own module ports.
3. Inject consumer-owned interfaces from `port`. Use the module's model values
   internally, while public input/output remain explicit application values with
   no GORM model, transport tags, HTTP/Cobra type, or SDK payload.
4. Load state, enforce actor/tenant permission and business preconditions, apply
   policy, persist required effects, then assemble output. Propagate context and
   distinguish absence from failure. Follow [Consistency](consistency.md) for
   contested transitions and atomic writes; success follows the commit point.
5. Extract reusable acceptance rules to [Validator](validator.md), conversions
   to [Mapper](mapper.md), and remaining reusable capabilities to [Service](service.md).
   A private receiver does not change a helper's responsibility.
6. Reach another module through its public use-case API. Keep its storage private.
   Preserve project error, logging/decorator, and composition contracts.

*Check:* every identifier follows noun/action naming; full input validation is
first; dependencies are ports; public operation values expose no persistence
representation; each helper has the right owner; required effects precede success.

## Example: query operation

`internal/modules/order/usecase/order_get_usecase.go`. The repository and access
validator contracts are in their respective recipes. Replace the module path.

```go
package usecase

import (
	"context"

	"example.com/project/internal/modules/order/port"
	bricksvalidator "github.com/cristiano-pacheco/bricks/pkg/validator"
)

type OrderGetInput struct {
	ID      uint64 `validate:"required,gt=0"`
	ActorID uint64 `validate:"required,gt=0"`
}

type OrderGetOutput struct {
	ID     uint64
	Status string
}

type OrderGetUseCase struct {
	orderRepository      port.OrderRepository
	validator            bricksvalidator.Validator
	orderAccessValidator port.OrderAccessValidator
}

func NewOrderGetUseCase(
	orderRepository port.OrderRepository,
	validator bricksvalidator.Validator,
	orderAccessValidator port.OrderAccessValidator,
) *OrderGetUseCase {
	return &OrderGetUseCase{
		orderRepository:      orderRepository,
		validator:            validator,
		orderAccessValidator: orderAccessValidator,
	}
}

func (uc *OrderGetUseCase) Execute(ctx context.Context, input OrderGetInput) (OrderGetOutput, error) {
	if err := uc.validator.Validate(input); err != nil {
		return OrderGetOutput{}, err
	}
	order, err := uc.orderRepository.FindByID(ctx, input.ID)
	if err != nil {
		return OrderGetOutput{}, err
	}
	if err := uc.orderAccessValidator.Validate(input.ActorID, order.OwnerID); err != nil {
		return OrderGetOutput{}, err
	}
	return OrderGetOutput{ID: order.ID, Status: order.Status}, nil
}
```

## Recipe: create and persist one entity

After full input validation, choose the operation's allowed initial state,
construct a module model value, call its persistence port, and map the persisted
result to explicit output. A generated ID/default must come from the persisted
result, not an assumed input. A uniqueness precheck cannot replace a constraint.
For multiple required writes or remote effects, select Consistency rather than
adding another unprotected side effect after this flow.

`internal/modules/order/usecase/order_create_usecase.go`. The pending initial
state is an example policy; retain the real operation's business contract.

```go
package usecase

import (
	"context"

	"example.com/project/internal/modules/order/enum"
	"example.com/project/internal/modules/order/model"
	"example.com/project/internal/modules/order/port"
	bricksvalidator "github.com/cristiano-pacheco/bricks/pkg/validator"
)

type OrderCreateInput struct {
	ActorID uint64  `validate:"required,gt=0"`
	Notes   *string `validate:"omitempty,max=2000"`
}

type OrderCreateOutput struct {
	ID     uint64
	Status string
}

type OrderCreateUseCase struct {
	orderRepository port.OrderRepository
	validator       bricksvalidator.Validator
}

func NewOrderCreateUseCase(repository port.OrderRepository, validator bricksvalidator.Validator) *OrderCreateUseCase {
	return &OrderCreateUseCase{orderRepository: repository, validator: validator}
}

func (uc *OrderCreateUseCase) Execute(ctx context.Context, input OrderCreateInput) (OrderCreateOutput, error) {
	if err := uc.validator.Validate(input); err != nil {
		return OrderCreateOutput{}, err
	}
	order, err := uc.orderRepository.Create(ctx, model.OrderModel{
		OwnerID: input.ActorID, Status: enum.OrderStatusPending, Notes: input.Notes,
	})
	if err != nil {
		return OrderCreateOutput{}, err
	}
	return OrderCreateOutput{ID: order.ID, Status: order.Status}, nil
}
```

Register the concrete constructor directly, as in the
[Fx example](fx.md#example-module-composition). Exposing creation over HTTP
separately selects the body, handler and route recipes. Only operations selected
for decoration under the execution profile above add a decorated publication.

## Operation contract and cross-module calls

Use [Application DTO](dto.md) when wrapper/shared-value ownership changes.
Keep one operation's fields explicit; a list input/output or an empty operation
still gets its own named wrappers. A public input/output never embeds or aliases
another operation's contract or includes a persistence model.

Call another module through its public application API. Build its input, forward
caller context, and consume its output/error. Do not import that module's model,
repository, validator, or private error catalog. A missing interaction is a
public API change within scope, not permission to bypass the boundary. Read
Module/Architecture only when ownership/dependency direction is being decided.

Before completion, reclassify every helper by its body and verify registration
of the intended public operation. Apply the project's logging/decorator policy;
a generic example does not authorize duplicating telemetry inside `Execute`.

At completion, verify that the chosen execution profile follows the selection
rule above and that callers resolve the intended direct or decorated instance.
