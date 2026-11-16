# Validator

Transport validates wire syntax. The use case validates operation-local input
with tags and the shared input validator. An extracted acceptance/rejection rule
has a named validator and consumer-owned port, including when it requires I/O.
GORM models remain data-only.

## Recipe: extracted acceptance rule

1. Create `port/<name>_validator.go` and `validator/<name>_validator.go`, both
   named `<Name>Validator`. The implementation asserts the port; its constructor
   returns a concrete pointer. Stateless is the default.
2. Give `Validate` one coherent acceptance rule. Return a stable module error
   for rejection and preserve dependency errors when evidence cannot be loaded.
   Add context and narrow read ports when the rule needs external data.
3. Keep conversion in [Mapper](mapper.md), mutation/orchestration in the use
   case, and actual I/O in an adapter. Reading external evidence does not turn
   an acceptance rule into a service.
4. Select [Consistency](consistency.md) when validity must survive a concurrent
   write. A preflight check cannot replace a database constraint or lock.

*Check:* the named port and implementation match; thresholds are explicit;
acceptance, rejection, boundaries, and unavailable evidence are proved at the
project-selected test boundary; no extracted rule is hidden in service helpers.

## Example: validator port

`internal/modules/order/port/order_access_validator.go`.

```go
package port

type OrderAccessValidator interface {
	Validate(actorID, ownerID uint64) error
}
```

## Example: stateless access rule

`internal/modules/order/validator/order_access_validator.go`.

```go
package validator

import (
	"example.com/project/internal/modules/order/errs"
	"example.com/project/internal/modules/order/port"
)

type OrderAccessValidator struct{}

var _ port.OrderAccessValidator = (*OrderAccessValidator)(nil)

func NewOrderAccessValidator() *OrderAccessValidator {
	return &OrderAccessValidator{}
}

func (v *OrderAccessValidator) Validate(actorID, ownerID uint64) error {
	if actorID == 0 || actorID != ownerID {
		return errs.ErrForbidden
	}
	return nil
}
```

## Recipe: rule requiring external evidence

Give the rule a narrow read dependency and context on `Validate`. A failed read
is a dependency failure, not proof that the input is invalid. Delegate extracted
pure checks to their named validator. Keep conversion and mutation outside.
For a contested write, validate the same state protected by the transaction or
conditional update; an earlier successful check cannot guarantee later validity.

## Example: I/O-backed validator port

`internal/modules/order/port/order_owner_validator.go`.

```go
package port

import "context"

type OrderOwnerValidator interface {
	Validate(ctx context.Context, orderID, actorID uint64) error
}
```

`internal/modules/order/validator/order_owner_validator.go`. Use when the rule
owns the evidence lookup. When the operation already holds the protected order,
pass its values to `OrderAccessValidator` instead of fetching a second snapshot.

```go
package validator

import (
	"context"

	"example.com/project/internal/modules/order/port"
)

type OrderOwnerValidator struct {
	orderRepository port.OrderRepository
	accessValidator port.OrderAccessValidator
}

var _ port.OrderOwnerValidator = (*OrderOwnerValidator)(nil)

func NewOrderOwnerValidator(repository port.OrderRepository, access port.OrderAccessValidator) *OrderOwnerValidator {
	return &OrderOwnerValidator{orderRepository: repository, accessValidator: access}
}

func (v *OrderOwnerValidator) Validate(ctx context.Context, orderID, actorID uint64) error {
	order, err := v.orderRepository.FindByID(ctx, orderID)
	if err != nil {
		return err
	}
	return v.accessValidator.Validate(actorID, order.OwnerID)
}
```

For length/range rules, use named threshold constants and prove both sides of
each threshold. For an evidence rule, prove accepted/rejected evidence and the
original collaborator failure at the project-selected boundary. Bind a new validator
through Fx only when the requested operation consumes it.
