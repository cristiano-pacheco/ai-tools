# Recipe routing

Identify the operation, owner, changed representations/dependencies and behavior
to prove. Read each matching recipe. Mixed work takes the union; expand only for
another changed contract or an unverified dependency. Inspect unchanged signatures
without loading their guides. Review selects every boundary under assessment;
documentation selects its subject. The skill entrypoint owns the stopping rule.

## Responsibility index

| Changed contract | Read |
| --- | --- |
| Package ownership, naming, imports, or reuse; also mandatory for every invocation | [Anti-patterns](anti-patterns.md) |
| Creating, renaming, or reviewing Go filenames, split files, ports, or test basenames | [Naming](naming.md) |
| Bricks package choice, framework API/version, new platform capability | [Bricks](bricks.md) |
| Process stack creation/change, server or migration graph | [Bootstrap](bootstrap.md) |
| New module, selecting packages, or deciding/changing module ownership/public boundary | [Module](module.md) |
| End-to-end operation, entrypoint location, collaborator sequence, or Input/Output return path | [Data flow](data-flow.md) |
| Dependency direction, representation boundary, or cross-module imports being designed/assessed | [Architecture](architecture.md) |
| HTTP DTO, decoding, route, middleware, pagination, response behavior | [REST](rest.md) |
| Bricks JSON decoding or decode error contract | [Request](request.md) |
| Bricks success/error rendering, validation details or response-write behavior | [Response](response.md) |
| Cobra command, flags, output, command registration, infrastructure command | [CLI](cli.md) |
| Consumer-owned interface, signature, representation, adapter conformance | [Port](port.md) |
| Shared application value, operation wrapper ownership, alias/embedding/compatibility | [Application DTO](dto.md) |
| Public business operation, input/output, policy, orchestration | [Use case](usecase.md) |
| Persistence port, GORM query/write, absence, scope, storage failure | [Repository](repository.md) |
| GORM record/view, persistence field type, schema, migration | [Model](model.md) |
| Extracted reusable acceptance/rejection rule, including external-evidence checks | [Validator](validator.md) |
| Shared DB pool, driver, health, primary/replica connection ownership | [Database](database.md) |
| Schema/backfill, ordered up/down SQL, embedding/runner contribution | [Migration](migration.md) |
| Remote-service protocol adapter | [Client](client.md) |
| Third-party capability / SDK adaptation | [Provider](provider.md) |
| Cache key/value, serialization, TTL, hit/miss/failure, invalidation | [Cache](cache.md) |
| Conversion, parsing, nested or collection assembly | [Mapper](mapper.md) |
| Reusable capability left after classifying validation, conversion, and I/O adaptation | [Service](service.md) |
| Error identity, classification, public rendering contract | [Error](error.md) |
| Atomic writes, concurrency, retry, idempotency, acknowledgement | [Consistency](consistency.md) |
| Fx provider, interface binding, module registration, named/grouped contribution, invocation, or hook registration | [Fx](fx.md) |
| Explicitly requested decoration, or changed publication/chain of an existing decorated use case | [Usecase decorator](usecase-decorator.md); direct execution remains the default in [Use case](usecase.md#execution-profile) |
| Coded error locale entry, language or locale asset contribution | [Locale](locale.md) |
| Log/span/metric behavior or reporting ownership | [Observability](observability.md) |
| Config source/overlay/env mapping, module typed settings, defaults/validation | [Configuration](configuration.md) |
| Lifecycle behavior, resource ownership, telemetry | [Runtime](runtime.md) |
| Behavioral proof, fixtures, assertions, test changes | [Test](test.md) |

## Capability examples

- **New persisted REST operation:** module ownership/package selection,
  architecture flow, REST, usecase, repository, model, affected mapping, wiring,
  and proof. Add validator/service only for a real extracted responsibility;
  add consistency/error guidance when those contracts apply.
- **REST over an existing operation:** HTTP DTO/handler/router and affected
  mapping/proof. Verify the public operation signature; reuse its policy and
  persistence. Expand for missing guarantees, not simply because it is called.
- **Storage correction behind an endpoint:** repository and storage proof;
  usecase if policy/scope propagation changes. An unchanged HTTP contract does
  not select REST, and an unchanged schema/model does not select model.
- **Pure mapper correction:** mapper and its behavioral proof. No module
  blueprint, runtime graph, or database guide without evidence of another change.

For multi-step work, record the playbook, selected guides, triggering evidence
and material unknowns. Update that record when the scope changes.
