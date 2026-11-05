# Migration command

Read when creating or changing the migration process. [Migration](migration.md) owns schema policy and SQL history. [CLI](cli.md) owns Cobra conventions.

1. Reuse the production modules' SQL assets. Include foreign-key owners and validate global version uniqueness and dependency order.
2. Build a migration-only graph. Resolve configuration, SQL contributions, and the runner without constructing HTTP, application repositories, decorators, or an unused application pool.
3. For Bricks APIs, connection URLs, and runner invocation, follow [Bricks handoff](bricks.md) to `recipes/migration-command.md`. Do not build a second runner or duplicate its configuration tutorial here.
4. Return failures through Cobra `RunE`. The executable reports them and chooses the exit status after cleanup. Verify actual cancellation and timeout support before promising that an in-flight migration can stop.
5. Exercise pending and no-change runs against controlled storage. Verify that the application can use the resulting schema without starting its server merely to run migrations.

Done when the command applies the same owned SQL as production, reports failures, closes its resources, and starts no unrelated process work.
