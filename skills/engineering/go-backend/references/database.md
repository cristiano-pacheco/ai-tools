# Database

Read for connection ownership, pooling policy, health, or topology. A query change with unchanged connection ownership does not load this guide.

## 1. Own the pool

The process owns each shared pool and its closure. Repositories borrow the initialized handle. They do not open or close a pool per operation. Use an established concrete wrapper to distinguish resources in the graph.

`internal/shared/database/database.go`:

```go
package database

import "gorm.io/gorm"

type ProjectDB struct {
    *gorm.DB
}

func NewProjectDB(db *gorm.DB) *ProjectDB {
    return &ProjectDB{DB: db}
}
```

The connection provider owns acquisition and cleanup. This wrapper adds no second lifecycle owner. Fx does not expose an embedded `*gorm.DB` automatically. Publish the same handle explicitly only when a real consumer needs it.

## 2. Select connection mechanics

For Bricks, follow [Bricks handoff](bricks.md). Use its PostgreSQL or SQLite guide for constructors, configuration, retries, pool defaults, and shutdown. Use its multiple-databases recipe only for several handles. Do not copy connection fields from another version or invent a DSN setting.

Configure GORM error translation before publishing the handle when repositories classify `gorm.ErrDuplicatedKey`. If the project uses driver codes instead, preserve that profile and prove the relevant SQLSTATE behavior. Never classify database message text.

## 3. Define deployment policy

Validate required credentials and pool bounds at their configuration owner. Keep secrets and connection strings out of logs. For primary/replica deployments, writes, migrations, transactions, and authoritative reloads use the primary. Define acceptable replica staleness before selecting a read handle. Read [Repository topology](repository-topology.md) only when query selection changes.

Do not substitute SQLite for PostgreSQL proof of locking, dialect, or concurrent transactions. Verify the selected dialect's connection and foreign-key behavior.

## 4. Prove the resource contract

Exercise the actual consumer when connection, startup, health, or closure changes. Graph validation and an unused provider do not prove connectivity. Keep construction, startup, readiness, and cleanup claims separate.

Done when each pool has one lifecycle owner, repositories receive the intended handle, error classification matches configuration, and changed runtime guarantees have evidence.
