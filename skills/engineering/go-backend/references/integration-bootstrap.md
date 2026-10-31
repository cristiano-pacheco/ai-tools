# Integration bootstrap

Read when adding/changing the real PostgreSQL/Redis fixture, migration stack or
composed module test. A pure mapper/validator test does not bootstrap containers.
Use `github.com/cristiano-pacheco/bricks/pkg/itestkit`; it already owns container
startup, mapped addresses, connections, migration invocation and teardown.

## Select the stack

| Required guarantee | Start / reset / construct |
| --- | --- |
| Persistence, constraint, transaction | `StartPostgres`; apply owned SQL; `TruncateTables(t)` per scenario; real repository/use case |
| Cache hit/miss/TTL/invalidation | `StartRedis`; `kit.Redis()`; reset the isolated test Redis per scenario; real cache |
| DB plus cache | One kit starts both; reset both; fresh SUT per scenario |
| Direct operation or module graph | Same real adapters plus production `Module`; resolve the concrete use-case pointer |
| Explicitly requested or existing decorated operation | Same real adapters plus production `Module`; resolve the decorated generic operation |
| HTTP API transport behavior | Select API end-to-end coverage under [Test policy](test-policy.md), outside this usecase/service integration fixture |
| Uncontrolled third-party effect | Replace only its application port, preserving the real controlled stack |

## Fixture ownership

Start from `itestkit.DefaultConfig()` and override fields. In v0.1.21 `New` replaces
the entire config when `PostgresImage` is empty, even for a Redis-only fixture.
Register `t.Cleanup(kit.Cleanup)` immediately after `New`, before any startup can
fail. Call each start/migration method once and fail immediately on an error:
the `sync.Once` implementation does not preserve the first error on a later call.
A failed kit is discarded, not retried as if it were fresh.

The suite in [Integration test](integration-test.md) uses only PostgreSQL and
one owned SQL directory. The same pattern starts Redis only when consumed:
`require.NoError(t, kit.StartRedis())`, then use `kit.Redis()` (a universal client).
`FlushDB` is appropriate only on that kit's dedicated Redis, never a shared service.
Keep suites/scenarios sharing `TruncateTables` or `FlushDB` sequential.

Use scoped `kit.Cleanup` by default on a shared development Docker host.
`itestkit.TestMain(m)` and `CleanupAll()` in the inspected baseline enumerate and
remove **all** containers with the `org.testcontainers` label, across projects.
Reserve that global wrapper for an isolated worker whose entire Testcontainers
inventory belongs to the run; do not copy it into concurrent local suites.
`Cleanup`, `StopPostgres` and `StopRedis` return no value. Cleanup is registered
once; a second teardown hook should not terminate the same container again.

## One path versus multiple modules

`kit.RunMigrations()` uses `Config.MigrationsPath` and resolves a relative
`file://` path from the consumer's nearest `go.mod`. It runs one migration
source. For one independent module, point at its real `migration/` directory.

For a stack with cross-module foreign keys, use the production embedded runner
and the complete set of real module filesystems. The baseline kit exposes its GORM handle but no migration DSN getter. Use the
underlying pgx connection configuration to build a properly escaped PostgreSQL
URL, as the executable suite's multi-module variation shows.

Choose one migration route for a kit. Do not call both `RunMigrations` and the
embedded runner against separate partial schemas. Verify global version uniqueness
and dependency order; grouped Fx slices do not order migrations.

## Composed proof

For a claim about runtime publication, use the owner module's actual `Module`.
Supply the kit's concrete shared database wrapper and Bricks validator; resolve
the concrete use-case pointer by default. Supply other configuration and
resources only when the actual tested consumer needs them.

Only an explicit decorator request or modification of an existing decorated
use case selects decorated proof. In that branch, provide real fixture
configuration for logger/i18n/decorators and a controlled metrics implementation
if repeated graphs would duplicate global Prometheus registration. Resolve
`ucdecorator.UseCase[Input, Output]`; invoking only the concrete pointer does not
exercise decorated publication/translation. Other decorated operations in the
project do not opt a new use case into this branch.

For HTTP route publication or listener readiness, use the API end-to-end
boundary defined by [Test policy](test-policy.md). Exercise the application's
production route discovery and setup through its listening server. Resolving a
route group or calling `Router().ServeHTTP` does not prove API end-to-end behavior.

In v0.1.21 Chi `OnStart` launches listeners asynchronously and can return before
a bind failure; the inspected newer checkout binds synchronously. Keep those
claims tied to the installed implementation. A passed `app.Start` in the older
release does not establish HTTP readiness.

*Check:* required stack only, cleanup registered before startup, real migrations
and adapters, isolated sequential resets, production publication when claimed,
and execution evidence. A compile-only or skipped integration run is unrun proof.
