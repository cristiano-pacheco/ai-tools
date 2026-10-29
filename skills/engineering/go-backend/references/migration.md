# Migration

Read for schema change, backfill, migration ordering/reversal, embedded schema
contribution, or runner behavior. A repository/model edit that only inspects an
unchanged schema does not automatically select migration implementation.

## Recipe: owned schema change

1. Use the project's ordered up/down naming and runner. With no convention, use
   `internal/modules/<module>/migration/<globally-unique-version>_<verb>_<noun>.up.sql` and the
   corresponding down file. Applied migrations stay immutable; add a new one.
2. Write schema first, then make the GORM model match column order, types,
   nullability, indexes, defaults, and constraints. ORM auto-migration is not the
   deployed-schema workflow.
3. Plan existing-data compatibility and overlapping application versions. For a
   non-null field, add nullable, backfill explicitly, then tighten when necessary.
   A down migration reverses only its owned change; document irreversible data loss.
4. Register the module's embedded filesystem through the existing Fx contribution
   consumed by server/migration commands. Reuse the runner and contribution type;
   do not execute migration from a handler, use case, repository, or initializer.
5. Prove fresh schema, upgrade from representative rows, and the supported reversal
   with real storage. A model-only test cannot prove SQL or deployment safety.

## Example: orders schema

`internal/modules/order/migration/20261029090000_create_orders.up.sql`. This schema
matches the canonical model; the owner relationship is an example integer scope,
not a fabricated foreign key to a table the project has not established.

```sql
CREATE TABLE orders (
    id BIGSERIAL PRIMARY KEY,
    owner_id BIGINT NOT NULL CHECK (owner_id > 0),
    status VARCHAR(20) NOT NULL DEFAULT 'pending'
        CHECK (status IN ('pending', 'confirmed', 'canceled')),
    notes TEXT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_orders_owner_id ON orders (owner_id);
```

`internal/modules/order/migration/20261029090000_create_orders.down.sql`.

```sql
DROP TABLE orders;
```

## Example: embedded files

`internal/modules/order/migration/migration.go`. Export the embedded files to
its existing runner adapter; its configured Fx result group must match that
runner's consumer. This file defines assets, not another migration system.

```go
package migration

import "embed"

//go:embed *.sql
var Files embed.FS
```

## Framework contribution and runner

`internal/modules/order/migration_fs.go`. The module `fx.go` publishes the
concrete result with `group:"migration_filesystems"`.

```go
package order

import (
	ordermigration "example.com/project/internal/modules/order/migration"
	bricksmigration "github.com/cristiano-pacheco/bricks/pkg/migration"
)

func provideMigrationFileSystem() bricksmigration.FileSystem {
	return bricksmigration.New(ordermigration.Files)
}
```

`internal/shared/migration/runner.go`. This bridge consumes module contributions
and returns the framework's concrete runner, not a new migration implementation.
The migration process consumes it; the server does not run schema changes implicitly.

```go
package migration

import (
	bricksmigration "github.com/cristiano-pacheco/bricks/pkg/migration"
	"go.uber.org/fx"
)

type Params struct {
	fx.In
	Files []bricksmigration.FileSystem `group:"migration_filesystems"`
}

func NewRunner(params Params) *bricksmigration.Runner {
	return bricksmigration.NewRunner(params.Files)
}

var Module = fx.Module("migration", fx.Provide(NewRunner))
```

`Runner.Up(postgresURL)` merges SQL filenames and uses golang-migrate. Versions
must be globally unique across modules and ordered by schema dependencies;
the order of the injected filesystem slice does not establish SQL order. In
v0.1.21 duplicate filenames overwrite during merge rather than producing a
reliable diagnostic. Allocate timestamp versions across the whole application
and check duplicates before running. Keep SQL files at the contribution root.

[Migration command](migration-command.md) shows the Cobra migration process consuming this graph.
`itestkit.RunMigrations` accepts one path, not a slice of module filesystems;
[Integration bootstrap](integration-bootstrap.md) shows how to use the same
embedded runner for a multi-module test. Do not manually recreate foreign-key
target tables to make a partial migration set pass.

*Check:* global unique versions, model/schema agreement, existing-data compatibility,
real grouped contribution/consumer, fresh/upgrade/reversal storage proof and no
implicit production migration on an application request.
