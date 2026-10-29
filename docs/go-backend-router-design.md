# Go backend router design

## Source inspected

Downloaded the official `cursor/plugins` repository and inspected PStack at
commit `1ba91fc25c0977741dd0e267849e6234b037ed0a`:

- [poteto-mode](https://github.com/cursor/plugins/blob/1ba91fc25c0977741dd0e267849e6234b037ed0a/pstack/skills/poteto-mode/SKILL.md): principles with triggers, playbook selection, numbered steps copied into the task list, and explicit reasons for skipped steps.
- [Feature](https://github.com/cursor/plugins/blob/1ba91fc25c0977741dd0e267849e6234b037ed0a/pstack/skills/poteto-mode/playbooks/feature.md): inspect the system, design the change, implement, verify at the matching surface.
- [Bug fix](https://github.com/cursor/plugins/blob/1ba91fc25c0977741dd0e267849e6234b037ed0a/pstack/skills/poteto-mode/playbooks/bug-fix.md): reproduce, establish the cause, correct it, repeat the reproduction.
- [Refactoring](https://github.com/cursor/plugins/blob/1ba91fc25c0977741dd0e267849e6234b037ed0a/pstack/skills/poteto-mode/playbooks/refactoring.md): pin observable behavior before changing structure, then prove equivalence.
- [Investigation](https://github.com/cursor/plugins/blob/1ba91fc25c0977741dd0e267849e6234b037ed0a/pstack/skills/poteto-mode/playbooks/investigation.md): read-only explanation supported by evidence.

PStack supplies a workflow router, not a Go backend package layout. Go component
recipes come from adapting the existing Go guidance to this skill's contracts.

## Go component baseline

Inspected the real JBN project alongside the existing Go recipe contracts:

| Contract | Project evidence |
| --- | --- |
| Noun/action operation names and complete input validation first | [order_get_usecase.go](/Users/cp/code/projects/jbn/internal/modules/order/usecase/order_get_usecase.go) and [product_get_usecase.go](/Users/cp/code/projects/jbn/internal/modules/catalog/usecase/product_get_usecase.go) |
| GORM persistence type, tags, and table name | [order_model.go](/Users/cp/code/projects/jbn/internal/modules/order/model/order_model.go) and [product_model.go](/Users/cp/code/projects/jbn/internal/modules/catalog/model/product_model.go) |
| Model values at the persistence interface; GORM pointers inside the adapter | [order_repository.go](/Users/cp/code/projects/jbn/internal/modules/order/ports/order_repository.go) and [product_repository.go](/Users/cp/code/projects/jbn/internal/modules/catalog/repository/product_repository.go) |
| Named validator with consumer-owned interface and constructor | [order_create_from_budget_validator.go](/Users/cp/code/projects/jbn/internal/modules/order/validator/order_create_from_budget_validator.go) |
| Separate handler, router, and wire DTO ownership | [order_handler.go](/Users/cp/code/projects/jbn/internal/modules/order/http/chi/handler/order_handler.go) and [order_router.go](/Users/cp/code/projects/jbn/internal/modules/order/http/chi/router/order_router.go) |

The reusable skill keeps GORM, Chi, Cobra, explicit operation wrappers, and
module-owned contracts. It reuses Bricks infrastructure through its actual pinned package APIs
and normalizes new role/reference names to the requested singular spelling.
Project-specific wrappers, business fields, and legacy departures are examples
to inspect rather than requirements copied into every service.

## Simplification

| Mechanism | Go Backend decision |
| --- | --- |
| Principles with conditional specialists | Five short principles; a separate responsibility index loads focused recipes. |
| Trigger selects a playbook | Six outcomes: implementation, bug fix, refactoring, tests, investigation, review. |
| Preserve playbook steps | Copy numbered steps into the task list; retain nonapplicable steps with reasons. |
| Verify on the matching surface | Use the real HTTP, Cobra, application, or storage seam for the claim. |
| Mode persists through follow-ups | Retain the playbook until the requested outcome changes. |
| Conditional context loading | Select by affected behavior or a named unverified guarantee; an imported/called component alone does not load its guide. |

## Module and recipe boundaries

The skill's `module.md` owns capability/package requirements and module public
boundaries. It defines a module as ownership of a business capability inside
the application, independent of process or Go-module deployment boundaries.
Its package table is open-ended and conditional: database ownership requires
GORM model/repository, REST requires handler/router and HTTP-owned DTOs, while
validator, mapper, service, and additional capability packages need an actual
responsibility. Creating a module does not scaffold the whole table.

`architecture.md` owns dependency and representation flow. `routing.md` owns
guide selection and stopping conditions. Component recipes own implementation
contracts and inline code. `fx.md` owns concrete-constructor publication and
interface binding through `fx.Provide`/`fx.Annotate`/`fx.As`; `runtime.md` owns
resource and lifecycle guarantees. A graph change selects Fx; a local adapter
method change with verified unchanged wiring does not. Read module guidance for ownership/package decisions;
read architecture for flow/dependency decisions; read only matching component
guidance for local edits. An endpoint reusing a verified operation does not
automatically reload its use-case or persistence guide.

The smaller router carries no model selection, mandatory delegation, autonomous
queues, PR landing pipeline, or dependency on PStack skills. Go examples remain
inline in their selected recipe. Package names are singular; CLI uses Cobra.

## Constructor contract

Struct constructors, including constructor methods, keep their successful
result concrete. A fallible constructor may return `(*Type, error)`; Fx adapts
the concrete instance to the consumed interface in the owning module's `fx.go`.
The Fx guide distinguishes interface-only publication, optional `fx.Self()`
publication, lazy construction, static validation, and runtime proof.

## Reference coverage

The implementation recipes recover the source Go skill's concrete contracts,
with Bricks package contracts and a concrete project database wrapper, following JBN.
Conditional branches remain separate Markdown references so richer examples do
not turn a small local edit into a full backend reading list.

| Source concern | Generic reference | Recovered implementation detail |
| --- | --- | --- |
| Repository | `repository`, `repository-query`, `repository-transaction`, `repository-topology` | Value-based CRUD port, generic/builder query selection, affected rows, zero/null update, limited reload, count/page, joins/views, transaction participants, primary/replica choice. |
| Model, enum, application DTO, port | `model`, `enum`, `dto`, `port` | GORM schema mapping, nullability and composite constraints, validated literal wrapper, explicit operation wrappers, consumer-owned interface and representation ownership. |
| Use case | `usecase`, `consistency` | Noun/action names, full tagged-input validation first, read/create/protected-transition examples, public cross-module API, atomic success after commit. |
| Mapper, validator, service | `mapper`, `validator`, `service` | Collection/fallible conversion, cause preservation, stateless and evidence-backed named rule, pure and I/O service, collaborator/DTO ownership. |
| HTTP | `rest` dispatching to `http-dto`, `http-handler`, `http-body`, `http-router`, `http-middleware`, `pagination` | Wire ownership, actual Bricks decoding limits, one public use case, framework response/error owner, routes and middleware, filters/order/metadata. |
| Cobra | `cli`, `command-test` | Business command mapping/context/writers, server Fx lifecycle, bounded shutdown, infrastructure command distinction, registered command proof. |
| Fx | `fx`, `fx-contribution` | Concrete construction, interface exposure, optional self exposure, named pools, grouped route provider and actual consumer. |
| Database/configuration/migration | `database`, `configuration`, `migration` | Shared lifecycle/pool owner, startup health, typed settings/precedence, schema-first up/down and embedded assets. |
| Remote/vendor/cache | `client`, `provider`, `cache` | Bounded contextual HTTP protocol, real pinned SDK verification, application/SDK isolation, explicit cache hit/miss/failure and serialization/TTL/invalidation. |
| Error and proof | `error`, `test`, `unit-test`, `integration-test`, `command-test` | Coded/localized errors, raw versus translated identity, seam-specific tests, itestkit-migrated storage and honest runtime limits. |

Framework helpers retain their real package names and signatures. Examples
either show complete standard/pinned-library code or require inspection of the
actual project's provider/loader/runner contract. The entry point remains the
small playbook/ownership router; specialist detail loads from a matching trigger.

## Framework adaptation audit

Inspected the production packages in `/Users/cp/code/lab/go/bricks` at
`v0.1.21-6-g00ff738`, compared the v0.1.21 module source pinned by JBN, and read
JBN's process commands, shared database, module Fx publication, HTTP adapters and
integration suites. The later checkout adds SQLite and changes listener startup;
the recipes do not attribute those APIs to v0.1.21.

| Source mechanism | Skill owner |
| --- | --- |
| `pkg/itestkit` PG/Redis lifecycle, migrations, resets | `integration-bootstrap`, executable `integration-test` suite |
| Shared database wrapper over Bricks lifecycle | `database`, repository/transaction examples |
| Concrete raw use cases and Fx publication through `ucdecorator.Wrap` | `fx`, `usecase-decorator`, HTTP/Cobra constructors |
| Existing `chi.Route`, response envelope and structured errors | `http-router`, `http-handler`, `http-body`, `error` |
| Typed YAML subtree/base/overlay/env loader | `configuration`, complete process base in `bootstrap` |
| Embedded migration and locale contributions | `migration`, `locale`, `fx-contribution` |
| Process-owned Zap, Prometheus, tracing and decorators | `bootstrap`, `observability` |
| Actual universal Redis publication and config projection | `cache`, conditional `bootstrap` branch |
| Framework page parser/limits/metadata | `pagination` |

Source inspection exposed contract traps worth retaining at their owners:
`itestkit.New` can replace a partial config; its once guards do not replay startup
errors; `TestMain` cleans all Testcontainers across the Docker host; error translation
reconstructs typed errors without a cause chain; Redis needs a plain-config
projection in the baseline; migration filename collisions overwrite; the body
parser's `More` check does not prove EOF; v0.1.21 HTTP start is asynchronous.
These are version-scoped observations, not claims about every Bricks release.

The skill router loads none of those details unless the corresponding boundary
is selected. All Go/SQL/YAML/JSON examples remain inline Markdown; temporary
extraction for validation is not shipped as physical source files.

Process bootstrap is itself a small selector. Server/base YAML, migration
commands and Redis lifecycle have separate references, so changing a cache
connection does not load server or migration code. The final examples were
extracted into a disposable module against Bricks v0.1.21: 70 Go blocks passed
compilation/tests and vet, including real PostgreSQL/Redis suites, grouped
migration execution through Cobra, raw/decorated Fx publication, localized error
codes, HTTP route discovery and cache corruption/TTL/removal. Markdown links
and inline-only source packaging were checked separately. These results do not
claim live HTTP listener readiness or OTLP export.

The decorated profile now has a dedicated production recipe and conditional
composition-test recipe, with two operation specializations, once-only
publication, actual factory config semantics and raw/translated identity proof.

The strengthened decorated profile was verified with 71 extracted inline Go
examples: tests and vet passed against Bricks v0.1.21, including the real
PostgreSQL suite resolving both public operation types through production Fx
providers, persisted creation, once-only metric observations, localized coded
rejection and disabled-chain raw identity.

## Explicit operation data flow

`data-flow.md` owns runtime sequence, entrypoint identity and Input/Output return
contracts. Its CLI and HTTP branches own the canonical complete entrypoint
examples; CLI/handler component guides link to them rather than copying code.
New business CLI entrypoints live in `cmd`, and their registered-command proof
checks one lookup, caller context and malformed syntax rejection before RunE.
The architecture guide now owns dependency direction without a competing runtime
flow. Optional validator/repository/service branches are not mandatory layers;
ports are dispatch contracts and models are passive data. Bootstrap registration
is explicitly separated from business execution.

The explicit data-flow examples were extracted with the full recipe set:
71 Go blocks passed unit/command tests and vet (including integration-tagged
source checks), and all 218 relative Markdown links resolved. Runtime database
behavior was unchanged in this edit and its integration suites were not rerun.

## Request/response contracts and text cleanup

Dedicated `request.md` and `response.md` now own Bricks parsing and wire/error
contracts. Handler/body guides link to them. Executable examples cover parser
classification and limitations, JSON/no-content success, validation details,
wrapped catalog errors, safe unknown failures and parser-to-renderer 413/415.
All 73 inline Go examples passed tests and vet, including integration-tagged
static checks, against v0.1.21; 238 relative links resolved. No database/runtime
implementation changed, so container suites were not rerun for this text edit.

The unslop pass removed 1,058 words from the previous text, 4.5 percent, excluding
the two new references. SKILL.md decreased from 82 to 68 lines. Routing/flow
repetition and filler were reduced; all previous Go blocks were compared after
gofmt and remained unchanged. The new references and tests add content beyond
that measured reduction.
