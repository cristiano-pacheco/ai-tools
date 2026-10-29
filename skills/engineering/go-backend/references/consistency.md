# Consistency

## Recipe: atomic application operation

1. Identify writes that must commit together and the use case owning that
   promise. One repository may own a complete local storage operation; work
   spanning repository implementations requires an application-owned scope.
2. Reuse the project's transaction provider. The GORM default is a consumer-owned
   `port.TransactionProvider` with `WithTX(ctx, func(tx *gorm.DB) error) error`.
   This explicit transaction contract is the exception allowing a GORM handle
   through an application port; keep it out of public operation input/output.
3. The provider owns begin/commit/rollback. Pass the same context and transaction
   to every participating repository method; return callback and commit failures.
   Roll back on failure/panic. Keep model arguments/results as values.
4. Validate shape before opening the scope. Check state-dependent permission
   and transitions with concurrency protection inside it. Use constraints,
   conditional/versioned updates, locking, or isolation for the actual invariant.
5. Return success after commit. Prove partial failure, contention, and rollback
   with real GORM-backed storage. A child repository opens no hidden transaction
   and never commits the application-owned one.

## Example: application transaction provider

`internal/modules/order/port/transaction_provider.go`.

```go
package port

import (
	"context"

	"example.com/project/internal/modules/order/model"
	"gorm.io/gorm"
)

type TransactionProvider interface {
	WithTX(ctx context.Context, fn func(tx *gorm.DB) error) error
}

type OrderTransactionalRepository interface {
	FindByIDTX(ctx context.Context, tx *gorm.DB, id uint64) (model.OrderModel, error)
	UpdateTX(ctx context.Context, tx *gorm.DB, order model.OrderModel) (model.OrderModel, error)
}
```

The participant interface uses the module model by value. The application
chooses atomic scope; a callback is preferred over manual commit/rollback ownership.

`internal/modules/order/repository/transaction_provider.go`.

```go
package repository

import (
	"context"

	"example.com/project/internal/modules/order/port"
	"example.com/project/internal/shared/database"
	"gorm.io/gorm"
)

type TransactionProvider struct{ db *database.ProjectDB }

var _ port.TransactionProvider = (*TransactionProvider)(nil)

func NewTransactionProvider(db *database.ProjectDB) *TransactionProvider {
	return &TransactionProvider{db: db}
}

func (p *TransactionProvider) WithTX(ctx context.Context, fn func(tx *gorm.DB) error) error {
	return p.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		return fn(tx.WithContext(ctx))
	})
}
```

The provider uses the primary in a read/write topology. GORM finalizes this
callback: callback failure/panic rolls back and success attempts commit; return
its error. If a project uses manual `CreateTX`, commit/rollback exactly once,
return commit failure, preserve operation plus rollback failures when available,
and propagate panic after cleanup. A child participant never finalizes the scope.

## Example: protected business transition

`internal/modules/order/usecase/order_confirm_usecase.go`. This sample allows
pending-to-confirmed for the owner. Adapt the actual business transition table;
a transaction alone does not protect a read-modify-write without locking or a
conditional/versioned write. Its `FindByIDTX` locks the selected row on databases
that support this locking contract.

```go
package usecase

import (
	"context"

	"example.com/project/internal/modules/order/enum"
	"example.com/project/internal/modules/order/errs"
	"example.com/project/internal/modules/order/port"
	bricksvalidator "github.com/cristiano-pacheco/bricks/pkg/validator"
	"gorm.io/gorm"
)

type OrderConfirmInput struct {
	ID      uint64 `validate:"required,gt=0"`
	ActorID uint64 `validate:"required,gt=0"`
}

type OrderConfirmOutput struct {
	ID     uint64
	Status string
}

type OrderConfirmUseCase struct {
	orders       port.OrderTransactionalRepository
	transactions port.TransactionProvider
	validator    bricksvalidator.Validator
	access       port.OrderAccessValidator
}

func NewOrderConfirmUseCase(
	orders port.OrderTransactionalRepository, transactions port.TransactionProvider,
	validator bricksvalidator.Validator, access port.OrderAccessValidator,
) *OrderConfirmUseCase {
	return &OrderConfirmUseCase{orders: orders, transactions: transactions, validator: validator, access: access}
}

func (uc *OrderConfirmUseCase) Execute(ctx context.Context, input OrderConfirmInput) (OrderConfirmOutput, error) {
	if err := uc.validator.Validate(input); err != nil {
		return OrderConfirmOutput{}, err
	}
	var output OrderConfirmOutput
	err := uc.transactions.WithTX(ctx, func(tx *gorm.DB) error {
		order, err := uc.orders.FindByIDTX(ctx, tx, input.ID)
		if err != nil {
			return err
		}
		if err := uc.access.Validate(input.ActorID, order.OwnerID); err != nil {
			return err
		}
		if order.Status != enum.OrderStatusPending {
			return errs.ErrOrderConflict
		}
		order.Status = enum.OrderStatusConfirmed
		updated, err := uc.orders.UpdateTX(ctx, tx, order)
		if err != nil {
			return err
		}
		output = OrderConfirmOutput{ID: updated.ID, Status: updated.Status}
		return nil
	})
	if err != nil {
		return OrderConfirmOutput{}, err
	}
	return output, nil
}
```

Bind the transaction provider and participant through Fx only when that
application operation needs them. The same concrete repository may implement
both consumed interfaces; publish both from the same constructor registration
rather than opening two independent transaction owners.

## Recipe: retries and durable external effects

Identify retry owner, bounded attempts, timeout/backoff, and the operation's
stable idempotency identity. A timeout can leave a remote outcome unknown;
retry only when the effect is safe to repeat or protected by deduplication.
Persist deduplication and business state atomically when that is the guarantee.

For an atomic database change plus eventual publication, write business state
and an outbox row in one database transaction. A separate dispatcher confirms
publication before marking the row complete. Delivery may repeat; consumers
need idempotency. A database transaction cannot roll back an external API call.

When changing workers or consumers, acknowledge completion only after the
promised durable effects. Distinguish permanent rejection, retryable failure,
and unknown outcome according to the runtime contract.

*Check:* each write has an atomicity owner; every transaction participant shares
its scope; concurrent requests preserve the invariant; retries and acknowledgement
cannot silently duplicate or lose the promised effect.
