# GORM model

## Recipe: map a table

1. Read the migration first. Create `model/<entity>_model.go` in the owning
   module, with type `<Entity>Model` and a `TableName()` method returning the
   exact table name. Keep package, imports, model, then `TableName` in that order.
2. Match columns, order, nullability, defaults, indexes, and numeric ranges to
   the schema. Use `uint64` for IDs, `time.Time` for timestamps, and pointers for
   nullable values. Add GORM tags for schema metadata and explicit exceptions.
3. Keep the model data-only. JSON contracts, business validation, queries, and
   state-transition policy have their own owners. Repository ports exchange
   model values; pointers required by GORM stay inside the repository.
4. Use `model/<purpose>_view.go` for a multi-table persistence projection and
   `<Purpose>View` for its type. Complex persistence criteria may live in `model`;
   keep SQL/GORM clauses inside the repository. Use primitive criteria for a
   small fixed lookup.
5. Change deployed schema through migrations. Verify current-data upgrades,
   fresh creation, constraints, and round trips using the project's real DB boundary.

Use-case input/output and HTTP DTOs contain no GORM models or views. A validated
status value belongs to `enum` when needed; the model stores its schema value.

## Schema-to-Go mapping

| Schema meaning | Go/default mapping | Boundary rule |
| --- | --- | --- |
| Primary/required foreign key | `uint64` | Check the actual database/driver numeric range. |
| Nullable foreign key | `*uint64` | Preserve absent versus zero; a zero ID is not absence. |
| Timestamp | `time.Time` / `*time.Time` | Preserve timezone and nullability from schema. |
| Nullable text/bool/number | `*string`, `*bool`, `*int64` | Avoid transport-driven optionality on database fields. |
| Signed money/count | `int64` / `*int64` in declared units | Match signedness and constraints; do not use floating point for exact cents. |
| JSONB | `[]byte` with `gorm:"type:jsonb"`, or the project's established JSON type | Serialize/parse at an owned mapper; never expose the storage representation as HTTP. |
| Composite uniqueness | Same named `uniqueIndex` on each participating field | The migration creates the actual constraint. |

Follow GORM snake-case mapping and add tags for required schema metadata, not
redundant field narration. Keep model fields in schema order. An ORM struct is
not a migration: changes to deployed columns require [Migration](migration.md).
A column default is not an input default contract; GORM may use defaults for
zero-valued create fields. Choose explicit insert/update fields when zero is a
legitimate stored value and prove the behavior against the configured driver.

## Persistence view and criterion

A multi-table projection returns `<Purpose>View` from the `model` package;
only selected persistence fields and required column aliases belong there.
A criterion such as `OrderSearchCriteria` contains typed search values, never
`url.Values`, application input structs, `gorm.DB`, or caller SQL. A small fixed
lookup needs primitive parameters, not a new criterion type. Read
[Repository query](repository-query.md) only when implementing the query itself.
Use [Enum](enum.md) when raw values must become validated application values.
Keep status strings on the stored model; the enum's constructor owns acceptance.

*Check:* `<Entity>Model`, GORM tags, and `TableName` match the migration; nullable
fields preserve absence; model values stop before the public operation output.

## Example: GORM model

`internal/modules/order/model/order_model.go`. This reduced model demonstrates
persistence shape, not the complete fields of a product's order. The migration
must establish the same table, columns, defaults, and allowed status values.

```go
package model

import "time"

type OrderModel struct {
	ID        uint64    `gorm:"primaryKey;autoIncrement"`
	OwnerID   uint64    `gorm:"not null;index"`
	Status    string    `gorm:"type:varchar(20);not null;default:'pending'"`
	Notes     *string   `gorm:"type:text"`
	CreatedAt time.Time `gorm:"autoCreateTime"`
	UpdatedAt time.Time `gorm:"autoUpdateTime"`
}

func (*OrderModel) TableName() string {
	return "orders"
}
```

## Example: nullable relationship and composite constraint

`internal/modules/order/model/order_item_model.go`. This optional relation is
used by the join example; its migration must match this shape and constraints.

```go
package model

type OrderItemModel struct {
	ID          uint64  `gorm:"primaryKey;autoIncrement"`
	OrderID     uint64  `gorm:"not null;uniqueIndex:idx_order_item_position"`
	Position    int     `gorm:"not null;uniqueIndex:idx_order_item_position"`
	ProductID   *uint64 `gorm:"index"`
	Description string  `gorm:"not null"`
}

func (*OrderItemModel) TableName() string { return "order_items" }
```
