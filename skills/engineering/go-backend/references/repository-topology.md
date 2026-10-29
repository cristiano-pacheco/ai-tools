# Repository read/write topology

Read only when a real primary/replica deployment or consistency-sensitive
connection choice is affected. Single-connection CRUD stays in Repository.
[Database](database.md) owns opening/configuring/lifecycling the connections.

## Connection selection

| Operation | Connection |
| --- | --- |
| Replica-safe query | Read connection |
| Create/update/delete | Write connection |
| Transaction/migration | Write connection |
| Reload that must observe the preceding write | Write connection or active transaction |

Keep explicitly named fields/wrappers. Never rely on an ambiguous promoted `DB`
from two embedded database types. A transaction participant always uses its
supplied `tx`; it never chooses read/write pools itself. Read-after-write is a
public consistency promise, not a guarantee a lagging replica gives for free.

## Example: alternative split adapter

`internal/modules/order/repository/read_write_order_repository.go`. This is an
alternative implementation of the same port, not another mandatory provider.
Its two GORM handles must come from distinct configured owners/names in the
actual graph. The normal single-connection constructor remains the default.

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
)

type ReadWriteOrderRepository struct {
	readDB  *gorm.DB
	writeDB *gorm.DB
}

var _ port.OrderRepository = (*ReadWriteOrderRepository)(nil)

func NewReadWriteOrderRepository(readDB, writeDB *gorm.DB) *ReadWriteOrderRepository {
	return &ReadWriteOrderRepository{readDB: readDB, writeDB: writeDB}
}

func (r *ReadWriteOrderRepository) find(ctx context.Context, db *gorm.DB, id uint64) (model.OrderModel, error) {
	value, err := gorm.G[model.OrderModel](db).Where("id = ?", id).Limit(1).First(ctx)
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return model.OrderModel{}, errs.ErrOrderNotFound
	}
	if err != nil {
		return model.OrderModel{}, err
	}
	return value, nil
}

func (r *ReadWriteOrderRepository) FindByID(ctx context.Context, id uint64) (model.OrderModel, error) {
	ctx, span := trace.Span(ctx, "ReadWriteOrderRepository.FindByID")
	defer span.End()
	return r.find(ctx, r.readDB, id)
}

func (r *ReadWriteOrderRepository) Create(ctx context.Context, value model.OrderModel) (model.OrderModel, error) {
	ctx, span := trace.Span(ctx, "ReadWriteOrderRepository.Create")
	defer span.End()
	if err := gorm.G[model.OrderModel](r.writeDB).Create(ctx, &value); err != nil {
		if errors.Is(err, gorm.ErrDuplicatedKey) {
			return model.OrderModel{}, errs.ErrOrderConflict
		}
		return model.OrderModel{}, err
	}
	return value, nil
}

func (r *ReadWriteOrderRepository) Update(ctx context.Context, value model.OrderModel) (model.OrderModel, error) {
	ctx, span := trace.Span(ctx, "ReadWriteOrderRepository.Update")
	defer span.End()
	result := r.writeDB.WithContext(ctx).Model(&model.OrderModel{}).Where("id = ?", value.ID).
		Select("status", "notes").Updates(&value)
	if result.Error != nil {
		return model.OrderModel{}, result.Error
	}
	if result.RowsAffected == 0 {
		return model.OrderModel{}, errs.ErrOrderNotFound
	}
	return r.find(ctx, r.writeDB, value.ID)
}

func (r *ReadWriteOrderRepository) Delete(ctx context.Context, value model.OrderModel) (model.OrderModel, error) {
	ctx, span := trace.Span(ctx, "ReadWriteOrderRepository.Delete")
	defer span.End()
	rows, err := gorm.G[model.OrderModel](r.writeDB).Where("id = ?", value.ID).Delete(ctx)
	if err != nil {
		return model.OrderModel{}, err
	}
	if rows == 0 {
		return model.OrderModel{}, errs.ErrOrderNotFound
	}
	return value, nil
}
```

Bind this constructor with named Fx parameters for read/write or with distinct
concrete wrapper types. The application supplies the actual two connections;
plain positional `*gorm.DB` parameters alone do not make Fx distinguish them.
Choose this implementation instead of the canonical adapter for that interface,
not both unnamed bindings at once. Keep the transaction provider on write.

*Check:* every query's owner/connection is explicit, update reload never uses
read, and controlled topology tests prove selection plus declared staleness.
A test using the same handle for both roles does not prove replica behavior.
