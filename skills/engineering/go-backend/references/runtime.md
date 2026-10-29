# Runtime and outbound adapters

## Recipe: compose an operation

1. Inspect the process entry point and registration path. Use the existing
   project graph and pinned APIs. Fx is the composition mechanism; read
   [Fx](fx.md) when providers, interface bindings, modules, or hooks change.
2. Construct adapters, validators/services when needed, use cases, and inbound
   handlers in dependency order. Bind consumed ports there. Verify the route
   or command is reachable from the intended executable.
3. Parse and validate configuration at startup into typed values; inject only
   the required subset. Keep credentials out of outputs. Preserve existing
   configuration precedence and defaults.
4. Give each resource one lifecycle owner. Propagate shutdown cancellation,
   stop accepting work, drain bounded in-flight work, then close dependencies.
   Startup failure cleans up resources already acquired. Request contexts stay
   on calls rather than long-lived structs.
5. Preserve project logging/tracing/metrics boundaries. Add business telemetry
   only for meaningful behavior; route registration alone needs no new runtime.

The [Fx module example](fx.md#example-module-composition) shows concrete
constructors published as consumed interfaces. Read it when implementing or
changing that graph. A configuration-value or adapter-method change with an
unchanged graph does not load Fx automatically.

## Recipe: external client or cache

Define application input/output at the consumer. Keep authentication, SDK
types, serialization, protocol statuses, bounded timeouts, and response mapping
inside the adapter. Verify APIs against the dependency version in the project.
Use [consistency](consistency.md) when retry or publication semantics change.

A cache contract distinguishes hit, miss, and failure. Declare the authoritative
source, TTL, fallback policy, and invalidation after a successful source commit.
Vendor responses and serialized cache values become application values before
returning to the use case.

*Check:* the composed entry point runs, missing configuration fails clearly,
resources close on failure/shutdown, and adapter technical types stay private.

## Resource and telemetry boundaries

A process must name each resource's constructor, start/health point, stop/drain
order, timeout, and owner. Acquire/release at that boundary; a copied adapter
example is not authority to create another pool, server, or provider client.
Startup errors stop readiness, and failed-start cleanup covers resources acquired
by the failing hook as well as successfully started resources Fx rolls back.
Request context flows through calls, not long-lived structs.

Use the project's tracing/metrics/logging mechanism. I/O adapter spans normally
cover one `Type.Method` operation and propagate its context, with `End` guaranteed.
Pure mapping/validation has no I/O tracing dependency. Shared use-case metrics/
tracing may belong to a decorator registered in Fx; selecting that injection
profile does not select metrics implementation unless the metrics contract changes.
Log failures at the declared reporting owner with safe contextual fields, avoiding
duplicate reports of the same propagated error and high-cardinality metric labels.

## Select the technical owner

- Changed DB driver, connection pool, replica topology, or health: [Database](database.md).
- Changed remote-service protocol: [Client](client.md); vendor capability/SDK: [Provider](provider.md).
- Changed cache keys, serialization, TTL, miss/failure policy: [Cache](cache.md).
- Changed source/overlay/environment mapping or typed settings: [Configuration](configuration.md).
- Changed provider bindings/contributions/hooks: Fx.

Read only the selected owner from Routing. For each affected resource, prove
startup failure, reachable healthy execution, caller cancellation, and bounded
cleanup through the project's real runtime boundary. An Fx graph or unit stub alone
establishes none of those external guarantees.

Read [Bootstrap](bootstrap.md) when process composition changes and
[Observability](observability.md) when reporting/span/metric behavior changes.
Bricks resource acquisition and readiness vary by version; use the actual
constructor/hook contract rather than inferring it from the `Module` name.
