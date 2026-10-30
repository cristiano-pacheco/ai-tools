# Data flow

Read when designing, explaining or reviewing an operation end to end, choosing
its entrypoint or assigning a step's owner. [Architecture](architecture.md) owns
imports/dependencies; [Module](module.md) owns package selection.

## The invariant

A business entrypoint converts transport values to one operation's **Input**,
calls that operation once, and converts its **Output** to a transport result.
`Execute(ctx, input) (Output, error)` receives Input and returns Output or error.
Input is not the return contract. The entrypoint never returns a persistence
model directly to the caller.

```text
                             APPLICATION
CLI RunE in cmd/*.go  --+
                       +------> concrete UseCase.Execute(ctx, Input)
HTTP handler method  --+               |
                                       +-- shape validator
                                       +-- optional named validator via port
                                       +-- optional repository via port -> database
                                       +-- optional service via port -> capability
                                       +-- optional client/provider/cache via port -> I/O
                                       |
                                       `-- constructs Output or returns error
                                                |
CLI writer / HTTP DTO <--------------------------+
```

The default entrypoint receives the concrete `*usecase.<Name>UseCase` and calls
it directly. Use [Usecase decorator](usecase-decorator.md) only when explicitly
requested or when changing an operation already decorated. A decorated neighbor
or application does not opt a new operation into decoration.

The operation selects these collaborators and their order. A validator
accepts/rejects, a repository accesses storage and a service performs a reusable
capability. One entrypoint calls one public operation; that operation may make
several collaborator or SQL calls.

A port is an interface type. Go dispatches `uc.orderRepository.FindByID` to
the concrete instance injected by Fx. A model holds persistence data; it adds
no executable step.

## Exact entrypoint and file ownership

| Responsibility | Default file/owner | Runtime action |
| --- | --- | --- |
| Process start | Executable main and `cmd/root.go` | Build required graph; register commands; call root ExecuteContext |
| Business CLI entrypoint | `cmd/<noun>_<action>_command.go`, Cobra RunE | Parse/map command values; invoke one public operation; write Output |
| HTTP process | `cmd/server_command.go` and Bricks server | Run HTTP lifecycle; no business operation for starting a server |
| HTTP route | `http/chi/router/<resource>_router.go` | Attach method/path/middleware to handler method |
| HTTP business entrypoint | `http/chi/handler/<resource>_handler.go` | Decode/map request; invoke one public operation; render HTTP DTO/error |
| HTTP wire values | `http/dto/<resource>_dto.go` | Request/response structures; no application workflow |
| Optional decorated operation | Module Fx publication, only for the selected decorated operation | Wrap its concrete instance once; publish its generic operation interface |
| Application operation | `usecase/<noun>_<action>_usecase.go` | Validate Input, decide/orchestrate policy and effects, construct Output |
| Collaborator contract | `port/<capability>_<role>.go` | Declare methods consumed by the application |
| Persistence data | `model/<entity>_model.go` | GORM record/schema mapping and persistence-owned views |
| Persistence implementation | `repository/<entity>_repository.go` | Contextual query/write; return model value/error |
| Named reusable acceptance rule | `validator/<name>_validator.go` | Accept/reject supplied facts or evidence loaded through its read dependency |
| Reusable capability | `service/<name>_service.go` | Perform its focused capability; preserve caller's policy/atomicity contract |
| Representation conversion | Owning `mapper` package | Pure conversion of supplied values; no hidden lookup or mutation |
| Object construction/binding | Owner `fx.go` | Construct concrete instances and bind them to consumed interfaces |

New CLI business entrypoints belong in `cmd`; do not introduce a second
module-level CLI entrypoint package. An established project's approved exception
is preserved outside the requested change, rather than copied as the default.
Constructors return concrete instances. Fx runs at composition; entrypoints and
use cases receive those dependencies instead of constructing them per call.

## One example operation, two transports

The canonical query is **get order 42 for authenticated actor 7**:

```text
Input:  OrderGetInput{ID: 42, ActorID: 7}
Read:   OrderModel{ID: 42, OwnerID: 7, Status: "pending"}
Rule:   actor 7 may read owner 7's record
Output: OrderGetOutput{ID: 42, Status: "pending"}

CLI:  app order:get --id 42 -> "42\tpending\n"
HTTP: GET /api/v1/orders/42 -> 200 {"data":{"id":42,"status":"pending"}}
```

| Boundary | Complete example | What it proves |
| --- | --- | --- |
| CLI | [CLI data flow](data-flow-cli.md) | Actual file in cmd, Cobra root registration, trusted identity, Input construction, Output writer and error return |
| HTTP | [HTTP data flow](data-flow-http.md) | Registered handler entrypoint, path/body distinction, separate DTOs, shared operation and response/error rendering |
| Application | [Use case](usecase.md) | Concrete get/create implementations, complete Input validation and explicit Output construction |
| Persistence | [Repository](repository.md) | Port dispatch to concrete GORM adapter and model values on return |

Select the affected CLI or HTTP branch; read both when comparing transports.
Both call the same operation and share its business policy.

## The application sequence

For `OrderGetUseCase.Execute`, the sequence is exact:

1. Receive caller context and `OrderGetInput`. Validate the complete tagged Input.
   Reject malformed application values before loading storage.
2. Call `port.OrderRepository.FindByID(ctx, input.ID)`. The injected implementation
   queries GORM using the initialized shared database and returns `OrderModel`.
3. Propagate a failed lookup. On success, pass actor and stored owner to
   `port.OrderAccessValidator.Validate`. Its rejection is an operation error.
4. Build `OrderGetOutput` from accepted state. Return Output and nil error.
5. The entrypoint receives Output/error directly and renders success only when
   error is nil. A selected decorated operation instead returns through its
   existing/requested decorator chain.

This query has no service, cache or transaction because its behavior needs none.
A write operation constructs/changes its module's model, calls its persistence
port and builds Output from the persisted result, including generated values.
Required durable effects and commit finish before the operation reports success.

Input tags validate field shape for every transport. Named validators enforce
extracted business rules. HTTP wire checks do not replace application validation.

## When a service or another adapter participates

A service does not become an obligatory wrapper between use case and repository.
For the existing [OrderConfirmationService example](service.md#example-service-input-and-provider-value),
the operation may request `port.OrderConfirmationService.Execute` with an
application `dto.OrderConfirmation`. The concrete service maps that value and
calls `port.EmailProvider.Send`; the provider adapts the external email system.

```text
business entrypoint
  -> concrete use case
       -> required validators
       -> repository for required stored state/effects
       -> OrderConfirmationService.Execute(ctx, application value), if promised
            -> pure mapper -> EmailProvider.Send(ctx, provider-independent value)
       -> explicit operation Output/error
  <- transport result/error
```

The operation owns whether/when notification is required and what failure means.
A database transaction cannot roll back a sent email. For an atomic state change
plus eventual delivery, use the [Consistency](consistency.md) outbox contract;
do not copy the diagram as a naive database-write-then-email transaction.
The exact collaborator subset and ordering must be stated before implementation.

## Return path, context and failure

| Value | May cross this boundary | Stops here |
| --- | --- | --- |
| Cobra arguments/flags, HTTP request/context/path/query/body | Transport -> its own parsing/mapping | Transport types do not become public operation fields |
| Operation Input | Entrypoint -> operation | Application-owned contract, independent of wire/storage/SDK types |
| Model value | Repository -> its module's application code | No model exposed as public Output or HTTP response |
| Operation Output | Application -> entrypoint | Transport maps it to its own output representation |
| HTTP response DTO | Handler -> Bricks JSON response | HTTP wire contract only |
| Error | Failed collaborator -> use case -> entrypoint | No success result rendered; shared boundary owns external representation |

Use `cmd.Context()` or `r.Context()` as the invocation context, and forward it
through I/O collaborators. A traced child context preserves cancellation and
values; it need not have the same pointer. Do not replace caller context with
`context.Background()` inside the business execution path.

Return on the first failure that prevents the operation's promised success.
The use case does not write HTTP status, print CLI diagnostics or choose an exit
code. A CLI entrypoint returns the error to its process owner; an HTTP entrypoint
passes it to the shared error renderer once. [Error](error.md) defines error
identity. For an explicitly selected decorated operation, its chain may observe
or translate Output/error before the entrypoint receives it.

## Completion check

Identify the file/method for entrypoint, Input, operation, each
collaborator, commit/effect, Output and transport result. Check that:

- The CLI entrypoint is in cmd, or the HTTP entrypoint is the registered handler.
- It constructs one Input and invokes one public operation, with caller context.
- Every business step has one owner; optional roles exist only for a real need.
- Application types stay independent of transport; model and SDK values stop at their owners.
- The use case returns Output/error; errors prevent success rendering.
- Fx constructs/binds and the default entrypoint calls the concrete use case.
  Any selected decorator chain wraps once and performs no business policy.
- The actual command/route is registered and its mapping/result are proved.

If any step's owner or returned representation is unclear, the flow is not ready
for implementation. Resolve that boundary before adding a helper or package.
