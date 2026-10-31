# Go artifact naming

Read before creating, renaming, or reviewing Go filenames. This is the naming
source of truth; component recipes define behavior, not naming exceptions.
Apply to new/renamed files without bulk-renaming unrelated existing code. An
explicit user/project contract overrides these defaults; neighboring filenames
alone do not establish such a contract. Report an intentional deviation.

## Role contract

Select the semantic role using [Component classification](component-classification.md)
before applying this matrix; suffixes do not determine responsibility.

Use lowercase `snake_case` filenames ending in the artifact's semantic role.
The package name does not replace the suffix. Use singular package names and
one primary component per file; its constructor and receiver methods stay with
it unless a real concern warrants a split. Do not combine unrelated components
in `helpers.go`, `utils.go`, `common.go`, or a generic package-named file.

| Artifact | Filename relative to its owner | Primary Go declaration |
| --- | --- | --- |
| Use case | `usecase/<noun>_<action>_usecase.go` | `<Noun><Action>UseCase`, `New<Noun><Action>UseCase`, `Execute` |
| Persistence record | `model/<entity>_model.go` | `<Entity>Model` |
| Persistence projection | `model/<purpose>_view.go` | `<Purpose>View` |
| Persistence criteria | `model/<purpose>_criteria.go` | `<Purpose>Criteria` |
| Repository | `repository/<name>_repository.go` | `<Name>Repository`, `New<Name>Repository` |
| Validator | `validator/<name>_validator.go` | `<Name>Validator`, `New<Name>Validator`, `Validate` |
| Service | `service/<name>_service.go` | `<Name>Service`, `New<Name>Service` |
| Protocol client | `client/<name>_client.go` | `<Name>Client`, `New<Name>Client` |
| SDK/capability provider | `provider/<name>_provider.go` | `<Name>Provider`, `New<Name>Provider` |
| Cache adapter | `cache/<name>_cache.go` | `<Name>Cache`, `New<Name>Cache` |
| Consumer port | `port/<capability>_<role>.go` | Same semantic role as the consumed capability; no `_port` or `_interface` suffix |
| Mapper | `mapper/<purpose>_mapper.go` | Pure `To<Destination>` functions; no synthetic struct/constructor |
| Application or HTTP DTO | `dto/<purpose>_dto.go` | Owned value/request/response types; no mandatory `DTO` type suffix |
| Enum/value wrapper | `enum/<name>_enum.go` | `<Name>Enum`, `New<Name>Enum` |
| HTTP handler | `http/chi/handler/<resource>_handler.go` | `<Resource>Handler`, `New<Resource>Handler` |
| HTTP router | `http/chi/router/<resource>_router.go` | `<Resource>Router`, `New<Resource>Router` |
| HTTP middleware | `http/chi/middleware/<purpose>_middleware.go` | Named middleware function or concrete component as behavior requires |
| Cobra business command | `cmd/<noun>_<action>_command.go` | `New<Noun><Action>Command` |
| Cobra infrastructure command | `cmd/<purpose>_command.go` | `New<Purpose>Command` |
| Module error catalog | `errs/<module>_error.go` | Stable named error values |
| Specialized error type | `errs/<purpose>_error.go` | Concrete error type; concrete constructor when needed |

HTTP-owned DTO/mapper paths are relative to `http/`. A port keeps its semantic
role even when the implementation lives in a different mechanism package:
`port/transaction_provider.go` and `repository/transaction_provider.go` define
and implement `TransactionProvider`; do not rename it to a repository merely
because it uses GORM. For additional or unresolved roles, use the classification
decision gate: present 2–3 justified options and obtain user agreement on the
responsibility and suffix before creating files.

## Splits and tests

Keep the role last when splitting a component by concern:
`repository/order_query_repository.go`, `order_summary_repository.go`,
`order_transaction_repository.go`, `order_exists_repository.go`.
These files extend `OrderRepository`; they do not introduce new structs or
constructors just to match filenames. Apply the same rule to other components,
such as `order_response_handler.go` or `order_policy_service.go`, only when
the split has a real responsibility. Component-private helpers remain receiver
methods under the skill's helper convention, including in split files.

Select an allowed boundary under [Test policy](test-policy.md) before naming
any test; filename conventions do not authorize excluded component suites.
Tests append `_test` to the complete production basename:
`order_get_usecase_test.go`, `order_access_validator_test.go`,
`password_hash_service_test.go`. Integration paths retain the same role-bearing
basename. A suite covering several artifacts names its actual boundary, such as
`order_usecase_decorator_test.go`, rather than dropping the component role.
For platform-specific Go files, put Go's build suffix after the role, for example
`shipping_client_linux.go` and `shipping_client_linux_test.go`.

## Explicit infrastructure and composition names

Role suffixes describe components, not every Go source file. These canonical
composition/resource files keep their purpose-based names:

- Executable `main.go`, Cobra `cmd/root.go`, process graph `cmd/application.go`.
- Module `fx.go`, `<concern>_fx.go`, `decorate_usecase.go`, `migration_fs.go`,
  and `locale_fs.go` for wiring/publication/resource contributions only.
- Owned `config/config.go`, shared `database/database.go`, embedded SQL
  `migration/migration.go`, and the shared migration `runner.go` bridge.
- Package documentation `doc.go` and tool-generated filenames required by the
  generator. Inspect generator/config evidence before treating a file as generated.

These are scoped exceptions, not permission for `service/service.go`,
`validator/validator.go`, or suffixless business components. Tests of the listed
infrastructure files retain their basenames, such as `config_test.go` or
`fx_test.go`. SQL migration and locale filenames follow their own recipes.

## Completion check

For every added/renamed Go file, identify its owner, semantic role, required
basename, and primary declaration. Check split files, ports, local/integration
tests, and build suffixes too. Correct mismatches before completion; document
any explicit project override or listed infrastructure exception. Assess helper
ownership across the component, not only the constructor's file.
