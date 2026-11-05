# Error

## 1. Own application rejections

Keep stable error identities in the owning module's `errs` package. Preserve the project's approved code allocation, public statuses, and error representation. A new endpoint does not authorize replacing that contract.

For a Bricks-backed catalog, follow [Bricks handoff](bricks.md) to `references/errs/usage.md`. That guide owns typed errors, details, cause behavior, and framework APIs. The response guide owns HTTP classification. Do not duplicate that implementation in this skill.

For an identity-only catalog, `internal/modules/order/errs/order_error.go` can use standard Go errors:

```go
package errs

import "errors"

var (
    ErrInvalidInput = errors.New("invalid order input")
    ErrOrderNotFound = errors.New("order not found")
    ErrForbidden = errors.New("order access forbidden")
    ErrUnauthenticated = errors.New("authentication required")
    ErrOrderConflict = errors.New("order conflict")
    ErrInvalidOrderStatus = errors.New("invalid order status")
    ErrInvalidDate = errors.New("invalid date")
    ErrDependencyUnavailable = errors.New("dependency unavailable")
)
```

This illustrates application identity. It is not a replacement for an established typed catalog. Its transport adapter must map known identities to the published safe code and status. A renderer that recognizes only framework typed errors will not classify these sentinels automatically.

## 2. Preserve causes where promised

Wrap unexpected errors with `%w`. Match identities with `errors.Is` and concrete details with `errors.As`. Keep fixed catalog values immutable. Allocate request-specific details separately.

`internal/modules/order/errs/order_conflict_error.go`:

```go
package errs

import "fmt"

type OrderConflictError struct {
    OrderID uint64
    Cause error
}

func NewOrderConflictError(orderID uint64, cause error) *OrderConflictError {
    return &OrderConflictError{OrderID: orderID, Cause: cause}
}

func (e *OrderConflictError) Error() string {
    return fmt.Sprintf("order %d conflict", e.OrderID)
}

func (e *OrderConflictError) Unwrap() []error {
    if e.Cause == nil {
        return []error{ErrOrderConflict}
    }
    return []error{ErrOrderConflict, e.Cause}
}
```

Use this additional type only when callers need the order identity and original cause. Public renderers must not expose its technical cause.

## 3. Check each public boundary

Translation or decoration may reconstruct an error and change pointer identity or its cause chain. Inspect the selected framework contract before promising `errors.Is` across that boundary. Assert stable code and status when those are the published guarantees. Keep translation outside repositories and operation policy.

Done when codes and identities remain stable, messages are safe, shared errors stay immutable, and tests distinguish raw identity from any translated public contract.
