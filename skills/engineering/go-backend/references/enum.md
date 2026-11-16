# Enum

Read for accepted literals, normalized parsing, or validated state values.
A GORM string field alone does not validate application input. Keep model
schema changes under Model and transition orchestration under Use case.

## Recipe: closed string value

Create `enum/<name>_enum.go` in this order: constants, membership set, wrapper,
concrete-value constructor, `String`, then any unexported receiver methods.
Keep constructor acceptance checks inline, as below, and the inner value private
so construction establishes the invariant. Normalize only if the external
contract explicitly permits it.

Before construction, list accepted values and define the stable invalid-value
error. The example's values are illustrative; product transitions require the
actual business contract. Known compile-time constants can be used directly;
raw input must pass the constructor. A validated value is independent of GORM.

## Example: validated status

`internal/modules/order/enum/order_status_enum.go`.

```go
package enum

import "example.com/project/internal/modules/order/errs"

const (
	OrderStatusPending   = "pending"
	OrderStatusConfirmed = "confirmed"
	OrderStatusCanceled  = "canceled"
)

var validOrderStatuses = map[string]struct{}{
	OrderStatusPending: {}, OrderStatusConfirmed: {}, OrderStatusCanceled: {},
}

type OrderStatusEnum struct{ value string }

func NewOrderStatusEnum(value string) (OrderStatusEnum, error) {
	if _, ok := validOrderStatuses[value]; !ok {
		return OrderStatusEnum{}, errs.ErrInvalidOrderStatus
	}
	return OrderStatusEnum{value: value}, nil
}

func (e OrderStatusEnum) String() string {
	return e.value
}
```

If transitions are part of the value contract, expose a focused method such as
`CanTransitionTo` with the permitted pairs in one explicit table/switch. The use
case still authorizes the actor, loads state, chooses the action, and persists
with concurrency protection. Construct the enum on every raw-input path, not
only in HTTP. Keep the storage string and public response mapping explicit.

*Check:* each literal is represented once in the set; tests cover every accepted
literal, a rejected value, case/whitespace behavior, and permitted/forbidden
transitions when present. Assert the invalid-value error through its identity.
