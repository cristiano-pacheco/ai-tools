# Database

Read for shared connection construction, pool settings, health, topology, or
lifecycle. Model/query edits with unchanged connection ownership do not select it.
Use Bricks `pkg/database` behind the application's concrete shared wrapper,
following the JBN approach. Repositories receive the initialized wrapper.

## PostgreSQL resource and Fx owner

`internal/shared/database/database.go`. Replace `ProjectDB` with the project's
established wrapper name. The wrapper distinguishes this database in the graph;
it contains no business policy. Bricks owns connection/retry/pool/close behavior.

```go
package database

import (
	bricksconfig "github.com/cristiano-pacheco/bricks/pkg/config"
	bricksdatabase "github.com/cristiano-pacheco/bricks/pkg/database"
	"go.uber.org/fx"
	"gorm.io/gorm"
)

type ProjectDB struct{ *gorm.DB }

func NewDatabase(cfg bricksconfig.Config[bricksdatabase.Config], lc fx.Lifecycle) (*ProjectDB, error) {
	db, err := bricksdatabase.NewWithLifecycle(cfg.Get(), lc)
	if err != nil {
		return nil, err
	}
	db.TranslateError = true
	return &ProjectDB{DB: db}, nil
}

var Module = fx.Module("database",
	bricksconfig.Provide[bricksdatabase.Config]("app.database"),
	fx.Provide(NewDatabase),
)
```

`TranslateError` is enabled before the handle is published because the repository
recipes classify `gorm.ErrDuplicatedKey`. Bricks v0.1.21 does not expose that flag
in its database config. With an established driver-code profile, retain that
profile instead and prove its SQLSTATE classification. Never classify message text.

Bricks `NewWithLifecycle` connects during construction and registers pool closure
on stop; it does not defer acquisition to `OnStart`. Its configured pool lifetimes
and retry behavior come from the installed implementation. Neither graph validation
nor registering an unused provider proves a live connection. Exercise the actual
consumer, health, failed startup, and shutdown when those guarantees change.

## Configuration contract

`app.database` decodes to `bricksdatabase.Config`: `host`, `port`, `name`, `user`,
`password`, `sslmode`, `maxopenconnections`, `maxidleconnections`, and the other
actual exported fields. Read [Configuration](configuration.md) for loading and
validation. The PostgreSQL config is structured; a made-up `dsn` field is not
recognized by this type. `DSN()` and `PostgresDSN()` have different formats.
Keep credentials and entire configs out of diagnostics.

The library's config validation requires host/name/user and a valid port;
validate any additional project policy, such as positive pool bounds and
idle <= open, at its configuration owner. Its URL builder in this baseline uses
string formatting for credentials; use correctly escaped URL components when
credentials contain reserved characters rather than assuming URL-safe values.

## Conditional topology and dialect

For a real primary/replica deployment, use distinct concrete wrappers or explicitly
named handles. Writes, migrations, transactions and authoritative reloads use the
primary; replica reads obey the declared staleness policy. Select
[Repository topology](repository-topology.md) only when query selection changes.
Fx does not automatically expose an embedded `*gorm.DB`; keep wrapper consumers
or publish the same inner handle explicitly if the project already uses that profile.

SQLite support exists in the inspected newer checkout, not in v0.1.21. Check the
resolved version before selecting `pkg/database/sqlite` or `Runner.UpSQLite`.
Follow its one-connection, foreign-key, busy-timeout and transaction semantics;
a PostgreSQL locking test cannot be replaced with SQLite evidence.

*Check:* one lifecycle owner per pool, concrete wrapper, actual config fields,
matching error translation, authoritative connection selection, and executed
connectivity/cleanup evidence for changed resource guarantees.
