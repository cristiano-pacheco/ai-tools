# Module

## Definition

Read when creating a module, selecting packages or changing ownership/public
boundaries.

A module owns one business capability and its public application operations.
Its code lives at `internal/modules/<module>`, such as `order`. It owns the
policy, representations, outbound contracts, adapters, and operational assets
needed for that capability. A module is an ownership boundary inside the
application; it does not require a separate executable or Go module.

Choose ownership from the behavior and data being changed, not the transport
that exposes it. An order operation exposed through REST and Cobra belongs to
the same module and reuses the same public use-case contract.

Apply [Naming](naming.md) when adding or renaming files, including optional
components, ports and tests. The tree illustrates that contract, not exceptions.

## Default expanded structure

Reference layout for an `order` module with GORM persistence and REST CRUD.
The tree expands package contents; it is not a create-all checklist. Entries
marked `[conditional]` exist only when the capability needs them. Keep package
names singular and preserve an existing project's approved spelling outside
the change scope. Route, migration and locale contributions reuse the Bricks contracts.

```text
internal/modules/order/
|-- fx.go                                      # constructors, interface bindings, contributions
|-- decorate_usecase.go                         # [conditional] explicitly selected decorated operations
|-- migration_fs.go                             # concrete SQL contribution
|-- locale_fs.go                                # [conditional] concrete locale contribution
|-- usecase/
|   |-- order_create_usecase.go                 # OrderCreateInput/Output, OrderCreateUseCase
|   |-- order_get_usecase.go                    # OrderGetInput/Output, OrderGetUseCase
|   |-- order_list_usecase.go
|   |-- order_update_usecase.go
|   |-- order_delete_usecase.go
|   |-- order_update_status_usecase.go          # [conditional] status operation
|   `-- order_generate_service_order_pdf_usecase.go  # [conditional] PDF operation
|-- port/
|   |-- order_repository.go
|   |-- order_item_repository.go                # [conditional] separately persisted items
|   |-- order_access_validator.go               # [conditional] extracted access rule
|   `-- generate_service_order_pdf_service.go   # [conditional] PDF capability contract
|-- model/
|   |-- order_model.go                          # OrderModel, GORM tags, TableName()
|   `-- order_item_model.go                     # [conditional] OrderItemModel
|-- repository/
|   |-- order_repository.go                     # implements port.OrderRepository
|   `-- order_item_repository.go                # [conditional] item persistence
|-- http/
|   |-- dto/
|   |   `-- order_dto.go                        # HTTP-owned request/response structs
|   |-- mapper/                                # [conditional] extracted wire conversion
|   |   `-- order_mapper.go
|   `-- chi/
|       |-- handler/
|       |   `-- order_handler.go                # decode -> one use case -> render
|       `-- router/
|           `-- order_router.go                 # paths and middleware attachment
|-- dto/                                       # [conditional] shared application values
|   `-- order_dto.go
|-- enum/                                      # [conditional] validated status values
|   |-- order_status_enum.go
|   `-- order_status_enum_test.go
|-- errs/
|   `-- order_error.go                         # coded module error catalog
|-- mapper/                                    # [conditional] application/model conversion
|   |-- order_mapper.go
|   `-- order_mapper_test.go
|-- validator/                                 # [conditional] extracted reusable rule
|   |-- order_access_validator.go
|   `-- order_access_validator_test.go
|-- service/                                   # [conditional] reusable PDF capability
|   |-- generate_service_order_pdf_service.go
|   `-- generate_service_order_pdf_service_test.go
|-- migration/                                 # owned schema and loader contribution
|   |-- migration.go
|   |-- 20261029090000_create_orders.up.sql
|   `-- 20261029090000_create_orders.down.sql
`-- locale/                                    # [conditional] localized module messages
    |-- en.json
    `-- pt_BR.json
```

Operation input/output stay in their use-case file. Module `dto/order_dto.go`
and `http/dto/order_dto.go` represent different owners; matching names or fields
do not merge their contracts. Shared input-validator infrastructure is reused,
not copied into every module. Test files shown above apply when the project's
test boundary permits local tests; infrastructure proof belongs to its integration
suite, commonly `test/integration/modules/order/` outside the module.

`cmd/root.go`, `cmd/server_command.go`, and `cmd/migrate_command.go` compose the
process outside the module. A business command has its entrypoint in
`cmd/order_get_command.go`; it invokes the module's public operation. Additional packages such as `client`,
`cache`, or `config` are added for their own responsibilities, using the rules below.

## Select packages from the capability

Choose packages by responsibility. Reuse existing owners; add other packages
when the capability needs them.

| Capability or responsibility | Required owner when present | Contract |
| --- | --- | --- |
| Public business operation | `usecase` | One noun/action operation, explicit input/output, `Execute`; owns policy and orchestration. |
| Outbound collaborator consumed by application policy | `port` | Consumer-owned interface; the implementation is supplied by composition. |
| Own data persisted or queried in a database | `model`, `repository`, repository interface in `port` | GORM `<Entity>Model` and persistence views; repository owns data access and returns model values. |
| REST API | `http/chi/handler`, `http/chi/router`, `http/dto` | Handler owns decoding/rendering and calls one use case; router owns paths/middleware; wire DTOs belong to HTTP. |
| Business CLI boundary | Cobra command in `cmd` | Parse/map, call one use case, render. Both transports reuse application policy. |
| Shared application representation | `dto` | Canonical value needed by multiple application collaborators; each operation retains its own wrappers. |
| Extracted representation conversion | Boundary-owned `mapper` | Pure functions; HTTP conversion stays under `http/mapper`, application/model conversion under module `mapper`. |
| Reusable acceptance/rejection rule | `validator` and its interface in `port` | Named rule implementation; external evidence adds read dependencies, not a new responsibility. |
| Validated value or state-transition value | `enum` | Explicit allowed values and transitions; persistence model remains data-only. |
| Reusable capability beyond validation, conversion, and I/O adaptation | `service` | Focused application capability; keep one public operation's orchestration in its use case. |
| Stable shared failure contract | `errs` | Module error identity consumed across its operation and adapters. |
| Concrete registration and resources | Module `fx.go` | Fx binds concrete instances to ports and publishes owned runtime contributions; resource hooks follow the lifecycle owner. |

Wire DTOs are separate from operation input/output, even when fields match.
Declare the request/response values that the HTTP contract actually carries;
a bodyless request or no-content response does not need a fabricated body DTO.
An HTTP handler has no business policy, repository, database, or provider call.

Pure input-shape validation stays in the use case through the shared input
validator. A trivial field copy may stay inline at its representation boundary.
Those cases do not require new `validator` or `mapper` packages.

## Extend by responsibility

Add a package when the requested behavior has a distinct owner the existing
roles do not cover: for example, `client` for a remote protocol, `cache` for
cache mechanics, or `config` for module-owned configuration. State its purpose,
consumer contract, and permitted dependencies before creating it. Keep names
singular and meaningful. A new dependency or helper alone does not justify a
package, and a remote-client payload is not a GORM model.

Module constructors return concrete instances; [Fx](fx.md) owns interface
bindings when composing those components. Read that guide when the graph changes.

Modules may contribute migrations, routes, configuration, locales, or templates
when their capability needs them. Shared technical infrastructure belongs to
`internal/shared`; business policy stays with its module. Preserve established
project paths outside the requested change.

## Public boundary

Expose public use-case inputs, outputs, and failure semantics. Another module
calls that application API rather than reaching into the owner's repository,
model, validator, or other implementation packages. Extend the public API when
the requested behavior needs a missing interaction; keep imports acyclic.

See [Architecture](architecture.md) when dependency direction or representation
flow is being designed or changed. Select component recipes through
[Routing](routing.md); this reference does not require reading them all.

*Check:* every required capability has an owner, each chosen package has a
present responsibility, public operations and owned data have one module, and
no package or loaded guide exists merely to complete a directory template.

Default new-project infrastructure follows [Bricks](bricks.md), with process
composition in [Bootstrap](bootstrap.md). Module `fx.go` registers concrete
constructors and consumers receive those instances directly by default.
[Use case](usecase.md#execution-profile) selects the execution profile;
`decorate_usecase.go` exists only for explicitly requested decoration or existing
decorated operations being maintained. A new operation stays direct even when
another operation in the module is decorated. This module tree does not require
loading every platform recipe for an isolated operation edit.
