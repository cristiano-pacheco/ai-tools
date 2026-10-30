# Routing cases

Maintenance acceptance cases for this skill. For each prompt, walk the router
and verify procedure, selected guides, conditional expansion, and completion
proof. These are routing checks, not claims that generated Go code was executed.

| Prompt / evidence | Expected route and proof |
| --- | --- |
| New empty project: "Create an endpoint to confirm orders"; fields and statuses supplied | Implementation; module, architecture, REST, usecase, affected mapping, model, repository, error, Fx, affected runtime, test; consistency for the contested transition. Select validator/service only for an extracted responsibility. Trace request through commit back to response. |
| Same request, transitions unspecified in project and prompt | Establish the technical default; ask only for the unresolved business transition. Do independent setup while keeping dependent behavior pending. |
| "Expose the existing order query as a CLI command" | Implementation; CLI, affected mapping, Fx if constructor/bindings change, test. Inspect unchanged use-case contract; reuse it without loading repository/model/usecase recipes for verified unchanged behavior. |
| "Add a column to the HTTP response", value already returned by use case | Implementation; REST -> HTTP DTO/handler as affected, mapper, selected test boundary. No module/architecture/usecase/repository/model loading unless another contract is changed or unverified. |
| "Fix SQL returning another tenant's orders", endpoint unchanged | Bug fix; repository, test; usecase if authorization/scope propagation is affected. Prove tenant isolation with real storage; select REST only if its contract is implicated. |
| "Create the server command" | Implementation; CLI infrastructure branch, runtime, test. No business use case. |
| "Change migration command help text" | Implementation; CLI and focused command proof. No schema migration or application setup. |
| "Extract a price conversion helper" | Refactoring; mapper, test; establish the behavior baseline before extraction. Add model only when units/types change. No service, validator, or constructor for pure conversion. |
| "Validate customer eligibility using external data" | Implementation; validator, error, test; Fx for a new adapter binding, consistency if validity must hold through a write. External I/O does not reclassify acceptance as a service. |
| "Confirm order and reserve stock atomically" | Implementation; usecase, repository, consistency, test; model/runtime only if affected. Prove shared transaction and rollback. |
| "Add regression coverage for an existing mapper" | Test; mapper, test. No runtime, HTTP suite, or production behavior change without evidence. |
| "Why does this CLI retry twice? Do not edit" | Investigation; CLI, consistency/runtime where retry ownership is defined. Answer with evidence and unknowns; no correction. |
| "Review the API and transaction boundary" | Review; REST, usecase, repository, consistency, relevant representations and test. Read-only findings with trigger and consequence. |
| Existing service uses a documented flat layout and constructor-based error | Preserve its layout and error contract. Apply layered ownership; do not migrate packages or replace its error system to match defaults. |
| Existing project uses a different ORM, HTTP router, or DI tool | Use pinned project APIs. No framework introduction or assumed helper calls. |
| "Improve query latency" | Implementation; repository, test, other affected guides. Require baseline and comparable measurement before claiming improvement. |
| Follow-up "continue" during a bug fix | Retain Bug fix and re-select affected guides if new evidence changes ownership. |
| New capability and role packages with no local naming precedent | Use `internal/modules/order` with singular `port`, `usecase`, `model`, `repository`, `validator`, `mapper`, and `service`. Plural routes and collection fields do not change package naming. |
| "Add a use case", requesting code guidance | Load the use-case recipe and its operation/port inline examples. Preserve explicit named input/output structs and constructor injection. Do not copy unrelated SQL or transports. |
| "Implement the response mapper" | Load mapper and the inline HTTP mapper example. Pure function in its owning package; no repository call, struct, interface, or constructor. |
| Existing HTTP router differs from the example | Keep its approved API contract. Use the Chi example for default setup; do not migrate an existing router outside scope. |
| Required integration database is unavailable | Report incomplete verification. Passing example unit tests does not satisfy the real-storage requirement. |
| "Create a CLI command" with no prior CLI | Use Cobra, a `*cobra.Command` constructor, `RunE`, `cmd.Context()`, and root `AddCommand`. Keep business policy in one use case. |
| Selected playbook has a nonapplicable step | Keep the numbered step in the task list with a reason. Required proof remains required. |
| A test-only request follows a feature discussion | Select Test for the newly requested outcome rather than continuing implementation implicitly. |
| "Create an order get use case" | File `order_get_usecase.go`, `OrderGetUseCase`, `OrderGetInput`, `OrderGetOutput`, `NewOrderGetUseCase`, and `Execute`. Validate the complete tagged input first; inject `port` contracts. |
| "Create an order persistence model" | `model/order_model.go`, `OrderModel`, GORM tags, nullable pointers, and `TableName() == "orders"`; no business behavior or JSON tags. |
| "Create a repository" | `port/order_repository.go` and `repository/order_repository.go`, `port.OrderRepository` and `repository.OrderRepository`, compile-time assertion, GORM `WithContext`, model values at the port, GORM pointers only internally. |
| "Create a Link model and repository", neighboring files are named `order.go` | Implementation; Model + Repository and affected proof. Create `model/link_model.go`, `port/link_repository.go`, and `repository/link_repository.go`; neighboring filenames do not override role suffixes. Check every added/renamed filename at completion. |
| Add tests for Link persistence | Test and affected Model/Repository boundary; use `link_model_test.go` or `link_repository_test.go` for the respective component, retaining the role suffix. |
| Add a multi-table persistence projection | Model + Repository query; use `<purpose>_view.go`, not `_model.go` merely because it lives in `model`. |
| Extract repository-local query assembly in a file with `NewLinkRepository` | Repository and affected proof; use an unexported method such as `func (r *LinkRepository) applyFilters(...)`, including when it needs no receiver fields. No package-level `func applyFilters(...)`. |
| Move a component helper to `link_helpers.go` in the same package | Refactoring; preserve behavior and receiver ownership. A sibling file does not make a package-level function private to the component; moving the free function fails the completion check. |
| Constructor needs a preparation helper before an instance exists | Keep preparation inline or in a function-local closure; no package-level private helper or artificial zero-value receiver. Constructor still returns a concrete instance. |
| A handler helper only converts supplied values to a response | Mapper + affected proof; extract a pure function to the owning mapper package, not a handler receiver method. No new struct/constructor for mapping. |
| Enum constructor checks accepted values | Enum and affected proof; keep checks inline as in the example, not in an unexported package-level acceptance function. |
| Explicit project contract requires suffixless persistence filenames | Follow the documented contract and report the deviation from the skill default; an existing suffixless filename alone is insufficient evidence. |
| Create or rename any Go component, port, split file, or test | Read Naming before selecting filenames; map every added/renamed artifact to its owner, role, basename, and primary declaration at completion. Existing generic filenames do not set the default. |
| "Create a Link get use case, access validator, and reusable capability" | Naming + affected Use case/Validator/Service recipes; `link_get_usecase.go`, `link_access_validator.go`, `link_processing_service.go`; matching `LinkGetUseCase`, `LinkAccessValidator`, `LinkProcessingService` and concrete constructors. Validator/service ports retain their roles. |
| Add protocol, SDK, or cache adapters | Naming + Client/Provider/Cache as applicable; `<name>_client.go`, `<name>_provider.go`, `<name>_cache.go` and role-matching ports/tests. Do not add all three for symmetry. |
| Add HTTP boundary components | Naming + affected HTTP recipes; `_handler.go`, `_router.go`, `_middleware.go`, `_dto.go`, `_mapper.go`. Types/functions follow each recipe; mappers remain pure functions. |
| Add an enum, persistence criteria, or error catalog | Naming + affected Enum/Model/Error recipe; `_enum.go`, `_criteria.go`, `_error.go`. Persistence views retain `_view.go`; DTO type names need no artificial DTO suffix. |
| Split an existing component into query, transaction, or response files | Naming + affected component recipe; retain role last, such as `order_query_repository.go`, `order_transaction_repository.go`, or `order_response_handler.go`. Extend the existing receiver; no new struct/constructor for a filename. |
| Create Cobra business/server/migration commands | Naming + CLI and affected process proof; `order_get_command.go`, `server_command.go`, `migrate_command.go`; command tests retain `_command_test.go`. `root.go` remains the explicit composition exception. |
| Test a use case, validator, or service in a local/integration suite | Naming + Test; preserve `order_get_usecase_test.go`, `order_access_validator_test.go`, `password_hash_service_test.go` regardless of directory. Platform files retain role before build suffix, such as `shipping_client_linux_test.go`. |
| Extract an internal helper from any constructed usecase, validator, service, client, provider, cache, handler, router, or middleware | Classify behavior first; component-internal logic becomes an unexported receiver method even without field access. Pure conversion belongs to Mapper. Package-level private helpers in the constructor file or sibling files fail completion. |
| Create Fx wiring, config, database wrapper, or migration resources | Naming lists scoped canonical exceptions such as `fx.go`, `config/config.go`, `database/database.go`, `migration/migration.go`; these do not justify `service/service.go` or `validator/validator.go`. |
| Add a TransactionProvider backed by GORM | Consistency + Naming; `port/transaction_provider.go` and `repository/transaction_provider.go` retain the semantic provider role, not the implementation directory name. |
| A new responsibility has no listed role suffix | State its owner, consumer contract, and proposed suffix; resolve the naming decision before file creation. Do not fall back to `helpers.go`, `utils.go`, or a generic package-named component file. |
| "Create a helpers/utils package for reused code" | Read Anti-patterns AP-001; reject the catch-all package and classify each behavior into its actual owner. Reuse does not itself justify Service or a new interface/constructor. |
| Existing `helper`, `helpers`, `util`, or `utils` package offers the needed function | AP-001 also prohibits new usages, not only new directories. Use the proper responsibility owner; address existing in-scope usage or report a scope blocker rather than importing the catch-all package. |
| Rename `utils` to `common` or `misc` | AP-001 still applies; a responsibility-free rename is not a fix. Assign coherent owners and preserve behavior at the affected test boundary. |
| Shared infrastructure lives under `internal/shared/database` | AP-001 permits a structural shared parent with a focused database package; it does not permit a miscellaneous `shared` Go package. |
| Add another AP-NNN entry to Anti-patterns | Mandatory entrypoint read reaches it on every invocation; include Pattern, Why, Use instead, Check and a matching acceptance case. Implementation applies it; read-only review reports rather than edits. |
| Maintain reference names | Files, link labels, and headings use singular `usecase`, `repository`, `model`, `validator`, `mapper`, `service`, `error`, and `test`; every renamed link resolves. |
| "Create an order module with a persisted REST operation" | Module defines ownership and capability requirements: usecase, port, GORM model/repository, own HTTP DTO, handler/router, and composition. Create only required roles; read component recipes for affected behavior. |
| "Create a module with a pure business calculation exposed by Cobra" | Module, the new flow's architecture, CLI/usecase, required Fx wiring, and proof. No model/repository merely to complete the module tree; no service for one operation's local orchestration. |
| "The module needs a remote shipping client" | Module permits a focused `client` package with a consumer-owned interface and application values. Runtime guidance covers protocol adaptation when affected. Provider payloads do not become GORM models; local DB packages require a separate storage need. |
| REST request/response currently have the same fields as operation input/output | Separate HTTP DTO ownership remains required. Map at that boundary; identical fields do not merge the representations. |
| Add a second transport over verified application behavior | Select its boundary and affected conversions/wiring/proof. Do not reload module, architecture, repository, or model solely because they are on the call path. |
| "Fix ordering in a GORM query", model and schema verified unchanged | Repository and real-storage proof. No model, REST, module, or runtime guide without another affected guarantee. |
| Cross-module persistence access is proposed | Module and architecture identify the public application boundary. Use another module's public operation contract; keep its repository/model private. |
| A selected example constructs a named validator but the requested operation has only local shape checks | Keep shared input validation in usecase. The example alone does not select validator, create its port, or add a runtime binding. |
| Add or change an interface-to-implementation binding | Fx; concrete `NewOrderRepository` return and `fx.Annotate(..., fx.As(new(port.OrderRepository)))` in module `fx.go`. Add runtime only for affected resources/lifecycle. |
| Construct a struct with a function or method | Return its concrete value/pointer, optionally with `error`; never hide the successful instance behind an interface. Pure constructor signature work does not itself require loading all Fx examples when the binding is verified unchanged. |
| Consumer needs both an interface and its concrete adapter | Fx; use `fx.As(new(port.OrderRepository))` plus `fx.As(fx.Self())` on the same provider when supported. Do not register the constructor twice. |
| Repository query changes but constructor, binding, and lifecycle are verified unchanged | Repository and storage proof; no Fx or runtime guide. |
| Add a path to an already constructed HTTP handler | REST route registration and proof; no Fx unless a provider or binding changes. |
| Static Fx validation passes but a constructor needs a live database | Graph validation is not startup/health proof. Exercise actual construction and real storage when those guarantees are in scope. |
| Repository CRUD with explicit zero/null updates | Repository only for CRUD mechanics; Model if fields change; prove selected fields and affected rows with storage. No replica/transaction guide without that contract. |
| Count/page or multi-table join changes | Repository -> Repository query; Model for changed view/criteria; real-storage proof for totals, stable order, and join cardinality. |
| Actual primary/replica connection selection changes | Repository topology; Database for connection ownership and Fx contribution for names; no automatic topology for ordinary CRUD. |
| HTTP wire field/tag edit only | REST -> HTTP DTO and affected conversion/proof. Do not load HTTP handler/body/router or persistence unless another contract changes. |
| HTTP byte limit, media type, null/trailing body behavior | REST -> HTTP body plus affected handler proof. No application/schema rewrite because body parsing changed. |
| Pure mapper tests | Test -> Unit test and Mapper. No Cobra example, integration fixture, or Fx module by default. |
| New migration with existing data | Migration and Model when representation changes; real upgrade/fresh/reversal proof; no DB pool guide without changed pool behavior. |
| Named Fx parameter or grouped route contribution | Fx -> Fx contribution; verify both provider and consumer tags and actual reachability. A basic interface bind does not load group examples. |
| New SDK provider | Provider and changed Port/DTO/Fx; inspect real pinned APIs rather than use fictional SDK method names. |
| Cache payload corrupted versus absent | Cache preserves failure versus miss; application fallback changes select Usecase only when that policy is affected. |

Check every relative Markdown link in the package resolves. Keep the entry
point small, recipes self-contained, and project-dependent APIs tied to
repository evidence. CLI recipes use Cobra.

## Bricks adaptation cases

| Prompt / evidence | Expected route and proof |
| --- | --- |
| New service with the standard stack | Implementation; Bricks + Bootstrap, affected module/component recipes. Reuse platform packages and process ownership; no custom loader/renderer/route registry/container test setup. |
| New database integration test | Test -> Integration test -> Integration bootstrap. Use itestkit defaults, scoped cleanup before startup, real owned migrations and fresh raw SUT; no DSN-skip path. |
| Integration suite needs Redis but no PostgreSQL | Start only Redis; build config from DefaultConfig so New does not overwrite supplied settings; test real TTL and isolated reset. |
| Cross-module foreign keys in integration | Use the complete embedded production migration set through the verified fixture bridge. No fake referenced table, fabricated kit DSN method or reliance on Fx group order. |
| App constructor returns interface to implement a port | Keep concrete result and bind with Fx. A Bricks external factory such as validator.New keeps its real public signature; do not invent its private implementation type. |
| User explicitly requests a new decorated use case | Usecase decorator; register raw constructor once; extend the one named fx.Out publication provider; HTTP/Cobra consume the generic public operation. Resolve it through production Module in composition proof. |
| New coded rejection | Error + Locale, module code/status and every required language entry. Raw singleton and translated error use different identity assertions. |
| Query local fix with verified pinned framework and graph | Repository + affected storage proof; no Bricks catalog, Bootstrap, Locale or decorators merely because those packages exist. |
| Shared Docker host running unrelated suites | Use scoped kit.Cleanup. The v0.1.21 TestMain/CleanupAll global label cleanup is not a run-scoped teardown. |
| README uses a method absent from the resolved module | Installed source wins. Correct the example and version evidence before using it. |
| New checkout supports SQLite/listener addresses, project pins v0.1.21 | Do not use newer APIs without an explicit dependency change and its own proof. |
| Strict request EOF is required | HTTP body; inspect the actual helper's limitations, strengthen the shared boundary and test trailing closing delimiters/unread bytes. Do not claim ReadJSON proves strict whole-body validity. |
| HTTP Fx Start succeeds under v0.1.21 | Report type/lifecycle evidence separately from real listener readiness; test the actual listener when that is the claim. |

| Decorated profile maintenance case | Expected route and proof |
| --- | --- |
| New public operation, even in an application with other decorated operations | Use case + affected Fx/transport proof; provide/inject the concrete pointer and call Execute directly. No Wrap, generic publication, decorator module/config, or decorator guide without an explicit request. |
| Change an existing decorated operation | Preserve its decorated contract; select Usecase decorator and its proof only when publication/chain behavior changes. Do not silently unwrap it. |
| User explicitly requests decorators | Usecase decorator; selected raw constructor + one module publication field/Wrap + generic consumer. Resolve the selected specialization through production Module. |
| New empty Bricks application, decorators not requested | Direct use cases by default; HTTP/Cobra inject concrete pointers. Server/Fx defaults include no ucdecorator factory/module, publication provider, or decorator YAML. |
| Existing direct operation, framework dependency includes ucdecorator | Keep the operation direct; dependency availability is not a request to wrap it. |
| Local raw policy correction, publication verified unchanged | Use case and affected behavior proof; no decorator-test or platform graph loading. |
| Decorator flag or publication behavior changes | Usecase decorator -> Usecase decorator test; test through real module publication, not manual test-only Wrap. |
| Omitted YAML flags | Loader zeros are not DefaultConfig; declare the intended flags and test actual decoded behavior. |
| Already published generic operation passed to Wrap again | Pass the raw concrete instance once; assert one expected metric observation per public call. |
| A raw use case injects its own public specialization | Reject the self-cycle; raw dependencies remain its collaborators, public wrapping remains in composition. |
| Distinct operations reuse type aliases for input/output | Aliases share Fx keys; keep distinct named operation wrappers or explicit named compatibility binding. |

| Data flow case | Expected route and contract |
| --- | --- |
| New CLI business operation | Data flow -> CLI branch; entrypoint in cmd, explicit Input, one public Execute, Output writer; policy stays in usecase. |
| New HTTP operation | Data flow -> HTTP branch; registered handler entrypoint, separate wire DTO, explicit Input/Output and shared rendering. |
| Return the input from the operation | Input is the received contract; construct and return the operation's distinct Output/error. |
| Add a service because the diagram lists one | Add only an actual reusable capability; a simple query uses repository and its required rule without an obligatory service. |
| Fx resolves a handler or registers a command | Composition is not business execution; assert the actual RunE/handler path invokes its public operation once. |
| Model/port depicted as extra runtime processing stages | Model is passive data; port dispatch calls the already injected implementation, not another object. |
| CLI-only mapping correction | CLI branch and command proof; do not load HTTP examples or unchanged persistence recipes. |

| Request/response case | Expected route and contract |
| --- | --- |
| Parser returns oversize/wrong media error | Request + Response; preserve framework code/status as 413/415 instead of replacing every error with 400. |
| Return an order DTO | Response; pass DTO directly to JSON for one data envelope. |
| Return tagged validation failure | Response; 422 INVALID_ARGUMENT and field details; test Go-field-derived names. |
| Unexpected database error reaches HTTP | Response; safe generic 500; original failure reporting belongs to the configured application logger. |
| JSON response write fails | Response; log and stop without a second error response or repeated operation. |
| API requires whole-body EOF validation | Request; stock More check is insufficient, strengthen the shared boundary and test trailing delimiters. |
