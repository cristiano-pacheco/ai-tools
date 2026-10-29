# Repository query

Read for count/page/filter behavior, joins, subqueries, persistence projections,
or ordering guarantees. A fixed ID lookup stays in [Repository](repository.md).

## Recipe: filtered collection

1. Declare accepted filters/sort and their application meaning at the operation.
   Map into primitives or a model-owned criterion; never accept SQL fragments or
   HTTP pagination objects in the repository port.
2. Build one filtered base query. Count before applying page limit/offset, then
   apply deterministic ordering and a unique tie-breaker to the page query.
3. Return an empty initialized collection and the total when nothing matches.
   Define whether count and page require a single consistent snapshot; two
   queries alone do not guarantee that under concurrent writes.
4. Values are parameters. Column names/order expressions come from fixed local
   allowlists. Escape wildcard characters when a filter promises literal text.

## Example: filtered count and page

`internal/modules/order/repository/order_query.go`. Add this method to the
consumed port only when a collection operation needs it. The caller validates
`limit > 0`, its maximum, and `offset >= 0` before the repository call.

```go
package repository

import (
	"context"

	"example.com/project/internal/modules/order/model"
)

func (r *OrderRepository) FindByOwnerID(
	ctx context.Context, ownerID uint64, limit, offset int,
) ([]model.OrderModel, int64, error) {
	base := r.db.WithContext(ctx).Model(&model.OrderModel{}).Where("owner_id = ?", ownerID)
	var total int64
	if err := base.Count(&total).Error; err != nil {
		return nil, 0, err
	}
	orders := make([]model.OrderModel, 0)
	err := base.Order("created_at DESC, id DESC").Limit(limit).Offset(offset).Find(&orders).Error
	if err != nil {
		return nil, 0, err
	}
	return orders, total, nil
}
```

## Recipe: multi-table view

Put a projection type in `model/<purpose>_view.go` and return it by value. Select
only required fields with explicit aliases. A join's cardinality is part of
correctness: joining one-to-many rows can duplicate entities and inflate counts.
Aggregate or deduplicate deliberately, and use the same meaning for page/total.
A one-table lookup remains on its table model unless a distinct persistence
projection is actually needed. [Model](model.md) owns view/criteria shape.

## Example: grouped persistence projection

`internal/modules/order/model/order_summary_view.go`.

```go
package model

type OrderSummaryView struct {
	OrderID   uint64
	OwnerID   uint64
	ItemCount int64
}
```

`internal/modules/order/repository/order_summary_query.go`. The example assumes
an owned `order_items(order_id)` relation exists in the migrated schema; it does
not instruct a query-only task to create it.

```go
package repository

import (
	"context"

	"example.com/project/internal/modules/order/model"
	"github.com/cristiano-pacheco/bricks/pkg/otel/trace"
)

func (r *OrderRepository) FindSummariesByOwnerID(ctx context.Context, ownerID uint64) ([]model.OrderSummaryView, error) {
	ctx, span := trace.Span(ctx, "OrderRepository.FindSummariesByOwnerID")
	defer span.End()
	rows := make([]model.OrderSummaryView, 0)
	err := r.db.WithContext(ctx).Model(&model.OrderModel{}).
		Select("orders.id AS order_id, orders.owner_id, COUNT(oi.id) AS item_count").
		Joins("LEFT JOIN order_items oi ON oi.order_id = orders.id").
		Where("orders.owner_id = ?", ownerID).
		Group("orders.id, orders.owner_id").Order("orders.id ASC").Scan(&rows).Error
	if err != nil {
		return nil, err
	}
	return rows, nil
}
```

*Check:* filters precede count/page; order has a tie-breaker; all input values
are bound; collection absence is successful; join cardinality and totals are
proved with real storage, including multiple children and zero children.
