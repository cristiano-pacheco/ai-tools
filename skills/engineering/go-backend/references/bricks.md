# Bricks package selection

Read when choosing infrastructure for a new project, introducing a Bricks
package, or checking a framework API/version. A local business edit with verified
infrastructure does not load this catalog.

Resolve Bricks from go.mod and any replace directive. Check the selected
package's implementation and Fx module. Examples were verified against v0.1.21,
the JBN baseline. A newer local checkout does not establish support in that
release, and these examples do not require a version change.

| Need | Bricks package under `github.com/cristiano-pacheco/bricks/pkg/` | Selected recipe |
| --- | --- | --- |
| YAML base/overlay, `env://`, typed subtree | `config` | [Configuration](configuration.md) |
| PostgreSQL GORM pool, retry, shutdown | `database` | [Database](database.md) |
| SQLite GORM pool | `database/sqlite`, only if present in the resolved version | [Database](database.md); verify dialect-specific transactions/migrations |
| Structured code/status/detail | `errs` | [Error](error.md) |
| Bounded JSON body | `http/request` | [Request](request.md) |
| Envelope and error renderer | `http/response` | [Response](response.md) |
| Server lifecycle and collected `Route` | `http/server/chi` | [HTTP router](http-router.md), [Bootstrap](bootstrap.md) |
| Tagged input validation | `validator` | [Use case](usecase.md) |
| Named acceptance rule | Application `port` + `validator` | [Validator](validator.md); the framework validates shape, not business eligibility |
| Locale files and error translation | `i18n`, `i18n/locale` | [Locale](locale.md) |
| Zap logging | `logger` | [Observability](observability.md) |
| Prometheus operation metrics | `metrics` | [Observability](observability.md) |
| OpenTelemetry lifecycle and spans | `otel/trace` | [Observability](observability.md) |
| Public operation decorators | `ucdecorator` | [Usecase decorator](usecase-decorator.md) |
| Page parsing/normalization/metadata | `paginator` | [Pagination](pagination.md) |
| Redis connection lifecycle | `redis` | [Redis](redis.md), [Cache](cache.md) |
| Embedded SQL runner | `migration` | [Migration](migration.md) |
| PostgreSQL/Redis containers and resets | `itestkit` | [Integration bootstrap](integration-bootstrap.md) |

Application-owned constructors return concrete instances. Consume external APIs
as actually declared: for example, `validator.New() (validator.Validator, error)`
returns the framework's interface; its implementation type is private. Register
`validator.Module` once instead of inventing an application constructor that
pretends to return that private type.

Create only needed infrastructure. A calculation needs no database; an added
HTTP field needs no new server; an established project keeps its accepted stack.
Reuse Bricks mechanisms instead of creating parallel loaders, renderers,
route registries, metrics chains, or container fixtures.
