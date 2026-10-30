# Repository

## Contract and scope

Application policy consumes `port.<Entity>Repository`; GORM lives in its concrete
`repository.<Entity>Repository`. Create `port/<entity>_repository.go` and
`repository/<entity>_repository.go`. The port uses model values, primitive
criteria, and persistence-owned criteria/views, never HTTP/application DTOs,
query builders, SDK values, or model pointers. Context is first on I/O methods.
Creates, updates, and deletes receive and return model values. A read returns a
model, collection, or model-owned multi-table view; totals may accompany lists.

Choose methods from real consumer needs. The example demonstrates CRUD; a
read-only capability need not copy its write methods. A missing single row is a
stable error; an empty collection is successful absence, never a dependency error.

## Recipe: construct, assert, and bind

1. Inspect the schema, GORM version, database wrapper, existing errors, and I/O
   instrumentation contract. Inject the shared database; opening connections
   belongs to [Database](database.md), not this constructor.
2. Order the file as type, interface assertion, concrete-pointer constructor,
   public methods, then unexported receiver methods for repository-owned helpers.
   Keep the assertion immediately below the type and initialize dependencies
   through named fields.
3. Use caller context on every operation. For supported pinned versions, use
   `gorm.G[model.X]` for fixed lookups/create/delete; put `Limit(1)` before
   `First(ctx)`. Use the traditional builder for targeted updates, dynamic
   predicates, joins, and projections. Preserve a project's approved API profile.
4. Translate known outcomes at this boundary and preserve unknown causes. Bind
   the constructor in module `fx.go` with `fx.As(new(port.OrderRepository))` when
   wiring changes; [Fx](fx.md) owns that registration recipe.
5. Apply project-owned tracing around each I/O method. Preserve its established
   span names and error-logging owner; adding a query does not authorize another
   telemetry framework or logging the same failure at every layer.

## Select the operation

| Need | Recipe / guarantee |
| --- | --- |
| One row | Parameterized identity/scope, limited first, typed not-found |
| Create | Model by value, pointer inside GORM, return generated fields |
| Update fixed fields | Explicit `Select` or map, affected-row check, reload on the same authoritative connection |
| Delete selected entity | Explicit scoped predicate, affected-row check, return the selected model value |
| Count/page, filters, joins, multi-table view | [Repository query](repository-query.md) |
| Adapter-local atomic writes or explicit `*TX` participant | [Repository transaction](repository-transaction.md) |
| Atomicity spanning application collaborators, retry/idempotency | [Consistency](consistency.md) |
| Primary/replica query selection | [Repository topology](repository-topology.md), only for a real split |
| Connection setup/pool/lifecycle | [Database](database.md), only when that ownership changes |

## Example: repository port

`internal/modules/order/port/order_repository.go`.

```go
package port

import (
	"context"

	"example.com/project/internal/modules/order/model"
)

// OrderRepository returns errs.ErrOrderNotFound for an absent single-row target.
type OrderRepository interface {
	FindByID(ctx context.Context, id uint64) (model.OrderModel, error)
	Create(ctx context.Context, order model.OrderModel) (model.OrderModel, error)
	Update(ctx context.Context, order model.OrderModel) (model.OrderModel, error)
	Delete(ctx context.Context, order model.OrderModel) (model.OrderModel, error)
}
```

## Example: GORM adapter

`internal/modules/order/repository/order_repository.go`. Replace the module path.
The initialized `*database.ProjectDB` follows the shared wrapper profile;
`gorm.G` receives its inner `DB`, while builder methods are promoted by embedding. GORM's generic API requires a compatible
pinned version. This example's update contract changes only status and notes.

```go
package repository

import (
	"context"
	"errors"

	"example.com/project/internal/modules/order/errs"
	"example.com/project/internal/modules/order/model"
	"example.com/project/internal/modules/order/port"
	"example.com/project/internal/shared/database"
	"github.com/cristiano-pacheco/bricks/pkg/otel/trace"
	"gorm.io/gorm"
)

type OrderRepository struct {
	db *database.ProjectDB
}

var _ port.OrderRepository = (*OrderRepository)(nil)

func NewOrderRepository(db *database.ProjectDB) *OrderRepository {
	return &OrderRepository{db: db}
}

func (r *OrderRepository) FindByID(ctx context.Context, id uint64) (model.OrderModel, error) {
	ctx, span := trace.Span(ctx, "OrderRepository.FindByID")
	defer span.End()
	order, err := gorm.G[model.OrderModel](r.db.DB).Where("id = ?", id).Limit(1).First(ctx)
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return model.OrderModel{}, errs.ErrOrderNotFound
	}
	if err != nil {
		return model.OrderModel{}, err
	}
	return order, nil
}

func (r *OrderRepository) Create(ctx context.Context, order model.OrderModel) (model.OrderModel, error) {
	ctx, span := trace.Span(ctx, "OrderRepository.Create")
	defer span.End()
	if err := gorm.G[model.OrderModel](r.db.DB).Create(ctx, &order); err != nil {
		if errors.Is(err, gorm.ErrDuplicatedKey) {
			return model.OrderModel{}, errs.ErrOrderConflict
		}
		return model.OrderModel{}, err
	}
	return order, nil
}

func (r *OrderRepository) Update(ctx context.Context, order model.OrderModel) (model.OrderModel, error) {
	ctx, span := trace.Span(ctx, "OrderRepository.Update")
	defer span.End()
	result := r.db.WithContext(ctx).Model(&model.OrderModel{}).
		Where("id = ?", order.ID).
		Select("status", "notes").Updates(&order)
	if result.Error != nil {
		return model.OrderModel{}, result.Error
	}
	if result.RowsAffected == 0 {
		return model.OrderModel{}, errs.ErrOrderNotFound
	}
	return r.FindByID(ctx, order.ID)
}

func (r *OrderRepository) Delete(ctx context.Context, order model.OrderModel) (model.OrderModel, error) {
	ctx, span := trace.Span(ctx, "OrderRepository.Delete")
	defer span.End()
	rows, err := gorm.G[model.OrderModel](r.db.DB).Where("id = ?", order.ID).Delete(ctx)
	if err != nil {
		return model.OrderModel{}, err
	}
	if rows == 0 {
		return model.OrderModel{}, errs.ErrOrderNotFound
	}
	return order, nil
}
```

## Known outcomes and mutation semantics

`gorm.ErrDuplicatedKey` is recognized only when the configured driver/error
translation supports it, commonly with `TranslateError: true`. Otherwise adapt
the project's driver classification, preserving SQLSTATE/cause; never inspect
rendered messages. Add the actual unique constraint before claiming uniqueness.
An ordinary create in this example has no business uniqueness promise beyond
its schema. Missing rows map to the module's declared absence contract.

Plain `Updates(struct)` skips zero values. An explicit selected field set writes
`nil`, `false`, `0`, and empty strings when those fields legitimately change.
Keep immutable ID/owner fields outside that set. A full update and a PATCH have
different presence semantics; resolve PATCH intent before building the model.
For optimistic updates, zero affected rows may mean a version conflict rather
than absence: define that port outcome instead of copying the CRUD default.
A bulk cleanup may validly affect zero rows; give that operation its own contract.

Scope mutations by the operation's required tenant/owner as well as identity.
An ID-only predicate is valid only for the explicitly authorized scope shown by
the caller contract; a repository never decides whether the actor is allowed.
Reload writes on the primary or active transaction, not a lagging replica.

## Completion

Verify constructor/assertion/port/Fx agreement; no DTO or pointer leaks; caller
context reaches every query; all target predicates are explicit. Real-storage
proof covers success, absence, duplicate constraints when present, zero/null
updates, scope, and negative state on failure. Load transaction/query/topology
specialists only for their matching guarantees, not every ordinary CRUD edit.
