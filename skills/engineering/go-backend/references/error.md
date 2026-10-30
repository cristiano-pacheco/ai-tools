# Error

## Coded module catalog

For a new Bricks-backed module, use `pkg/errs` and own stable codes in module
`errs`. Follow existing code allocation and public statuses. Transport renders
safe catalog text; unknown driver/SDK errors retain their causes and become a
generic internal error through `response.ErrorHandler`.

`internal/modules/order/errs/order_error.go`. Codes below illustrate one module's
allocation; allocate from the real catalog rather than duplicating these IDs.

```go
package errs

import (
	"net/http"

	brickserrs "github.com/cristiano-pacheco/bricks/pkg/errs"
)

var (
	ErrInvalidInput          = brickserrs.New("ORDER_01", "invalid order input", http.StatusBadRequest, nil)
	ErrOrderNotFound         = brickserrs.New("ORDER_02", "order not found", http.StatusNotFound, nil)
	ErrForbidden             = brickserrs.New("ORDER_03", "order access forbidden", http.StatusForbidden, nil)
	ErrUnauthenticated       = brickserrs.New("ORDER_04", "authentication required", http.StatusUnauthorized, nil)
	ErrBodyTooLarge          = brickserrs.New("ORDER_05", "request body too large", http.StatusRequestEntityTooLarge, nil)
	ErrUnsupportedMediaType  = brickserrs.New("ORDER_06", "unsupported media type", http.StatusUnsupportedMediaType, nil)
	ErrOrderConflict         = brickserrs.New("ORDER_07", "order conflict", http.StatusConflict, nil)
	ErrInvalidOrderStatus    = brickserrs.New("ORDER_08", "invalid order status", http.StatusUnprocessableEntity, nil)
	ErrInvalidDate           = brickserrs.New("ORDER_09", "invalid date", http.StatusUnprocessableEntity, nil)
	ErrDependencyUnavailable = brickserrs.New("ORDER_10", "dependency unavailable", http.StatusServiceUnavailable, nil)
)
```

Return the shared catalog value unchanged for a fixed rejection. Create a fresh
`brickserrs.Error` for request-specific `Details`; never mutate a shared catalog
pointer. Use nonzero catalog statuses and safe public messages/details.
[Response](response.md) owns HTTP classification, including validation errors;
[Request](request.md) owns decode errors. Keep their existing codes/statuses.

## Identity, causes and localization

- Raw catalog values can be checked with `errors.Is`, including through normal
  `%w` wrapping. Unexpected causes remain recognizable through `%w`.
- `brickserrs.Error` in v0.1.21 implements neither `Is` nor `Unwrap`.
  Its `OriginalError` field is not an automatic Go error chain.
- The i18n translator creates a new error preserving code/status/details when
  a translation exists. Pointer identity and an enclosing cause chain do not
  survive that reconstruction. At the decorated boundary, use `errors.As` and
  compare stable `Code`/`Status`; do not promise `errors.Is` to the raw singleton.
- [Locale](locale.md) owns catalog translations. [Usecase decorator](usecase-decorator.md)
  owns application publication; translation does not belong in repository code.

Preserve an established project's other approved error profile. Changing a
catalog/renderer/localization contract is an explicit compatibility change,
not a side effect of adding an endpoint.

## Example: detail plus recognizable technical cause

`internal/modules/order/errs/order_conflict_error.go`. Use this additional type
only when the application's raw contract needs order identity and an original
cause. Its concrete constructor and multi-error chain let the raw error renderer
find the catalog and callers find the cause. A translating decorator still has
the reconstruction limitation above.

```go
package errs

import "fmt"

type OrderConflictError struct {
	OrderID uint64
	Cause   error
}

func NewOrderConflictError(orderID uint64, cause error) *OrderConflictError {
	return &OrderConflictError{OrderID: orderID, Cause: cause}
}
func (e *OrderConflictError) Error() string { return fmt.Sprintf("order %d conflict", e.OrderID) }
func (e *OrderConflictError) Unwrap() []error {
	if e.Cause == nil {
		return []error{ErrOrderConflict}
	}
	return []error{ErrOrderConflict, e.Cause}
}
```

*Check:* unique stable code, safe nonzero status/message, fresh per-request details,
raw versus decorated identity assertions, recognizable unexpected causes where
promised, and one compatible renderer per inbound boundary.
