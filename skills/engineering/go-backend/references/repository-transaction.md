# Repository transaction

Read when a repository operation has atomic related writes, or implements an
explicit application transaction participant. [Consistency](consistency.md)
defines ownership across application collaborators. Keep ordinary CRUD independent
of an implicit larger transaction.

## Local versus application ownership

- One repository operation may own `WithTX` when all required writes stay inside
  that adapter. Keep adapter-local helpers out of the application port.
- A use case spanning repository implementations uses the module transaction
  provider. Its participating port methods accept context first and `*gorm.DB`
  second; model input/output remain values. This is the explicit GORM exception.
- The callback's transaction is authoritative for every participant and reload.
  A participant never falls back to `r.db`, begins a nested scope, or commits.

## Example: adapter-local scope and participants

`internal/modules/order/repository/order_transaction.go`. The methods below are
additions to the canonical adapter, not another constructor or database provider.

```go
package repository

import (
	"context"
	"errors"

	"example.com/project/internal/modules/order/errs"
	"example.com/project/internal/modules/order/model"
	"example.com/project/internal/modules/order/port"
	"github.com/cristiano-pacheco/bricks/pkg/otel/trace"
	"gorm.io/gorm"
	"gorm.io/gorm/clause"
)

var _ port.OrderTransactionalRepository = (*OrderRepository)(nil)

func (r *OrderRepository) FindByIDTX(ctx context.Context, tx *gorm.DB, id uint64) (model.OrderModel, error) {
	ctx, span := trace.Span(ctx, "OrderRepository.FindByIDTX")
	defer span.End()
	var order model.OrderModel
	err := tx.WithContext(ctx).Clauses(clause.Locking{Strength: "UPDATE"}).
		Where("id = ?", id).Limit(1).First(&order).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return model.OrderModel{}, errs.ErrOrderNotFound
	}
	if err != nil {
		return model.OrderModel{}, err
	}
	return order, nil
}

func (r *OrderRepository) WithTX(ctx context.Context, fn func(*gorm.DB) error) error {
	ctx, span := trace.Span(ctx, "OrderRepository.WithTX")
	defer span.End()
	return r.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		return fn(tx.WithContext(ctx))
	})
}

func (r *OrderRepository) CreateTX(ctx context.Context, tx *gorm.DB, order model.OrderModel) (model.OrderModel, error) {
	ctx, span := trace.Span(ctx, "OrderRepository.CreateTX")
	defer span.End()
	if err := gorm.G[model.OrderModel](tx.WithContext(ctx)).Create(ctx, &order); err != nil {
		if errors.Is(err, gorm.ErrDuplicatedKey) {
			return model.OrderModel{}, errs.ErrOrderConflict
		}
		return model.OrderModel{}, err
	}
	return order, nil
}

func (r *OrderRepository) UpdateTX(ctx context.Context, tx *gorm.DB, order model.OrderModel) (model.OrderModel, error) {
	ctx, span := trace.Span(ctx, "OrderRepository.UpdateTX")
	defer span.End()
	db := tx.WithContext(ctx)
	result := db.Model(&model.OrderModel{}).Where("id = ?", order.ID).
		Select("status", "notes").Updates(&order)
	if result.Error != nil {
		return model.OrderModel{}, result.Error
	}
	if result.RowsAffected == 0 {
		return model.OrderModel{}, errs.ErrOrderNotFound
	}
	updated, err := gorm.G[model.OrderModel](db).Where("id = ?", order.ID).Limit(1).First(ctx)
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return model.OrderModel{}, errs.ErrOrderNotFound
	}
	if err != nil {
		return model.OrderModel{}, err
	}
	return updated, nil
}
```

GORM `Transaction` owns rollback on callback error/panic and commit on success;
its returned error includes commit failure. Return the first callback failure.
Do not call `Begin`, `Commit`, or `Rollback` inside this callback. For a local
operation, assign its candidate output inside the callback but return it as
success only after `WithTX` returns nil. Use-case scope instead selects the
provider in Consistency, not a second repository's local `WithTX`.

If the application consumes these participants, extend the same persistence
interface with `CreateTX(ctx, tx, model)` / `UpdateTX(ctx, tx, model)` using the
signatures above. Load [Port](port.md) for the changed interface and [Fx](fx.md)
only if provider construction/binding also changes.

*Check:* a failed second write rolls back the first, a successful callback commits
all required writes, participants share context/transaction, and a reload reads
the transaction's state. Test commit failure when the test setup can induce it.
