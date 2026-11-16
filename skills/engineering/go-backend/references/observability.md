# Observability

Read when changing logs, spans, metrics, or their ownership. A local business edit does not automatically select observability work.

## 1. Assign reporting owners

Record unexpected failures once at the established owner. Keep credentials, tokens, raw operation payloads, and provider responses out of telemetry. Adapter spans may add technical location without repeating the same error log at every layer.

Direct use cases remain the default. Do not assume a logging decorator exists. Select [Usecase decorator](usecase-decorator.md) only for explicitly requested decoration or a changed existing chain.

## 2. Place instrumentation

Keep generic operation timing and outcomes outside raw policy when a selected decorator owns them. Put distinct I/O spans around the actual repository, client, provider, or cache call. Pure mappers and pure validators need no span or logger merely for symmetry.

Forward the derived context to downstream calls. A created span does not prove HTTP context extraction or distributed propagation. Verify the actual transport integration when that guarantee changes.

## 3. Select framework mechanics

For Bricks logging fields, metrics registration, tracing exporters, or shutdown, follow [Bricks handoff](bricks.md). Load only the requested component or composition recipe. Do not duplicate those APIs in every adapter example.

Respect actual global registration and tracer lifetimes. Several test graphs may collide even when their module instances are distinct. Use controlled dependencies or isolated processes where required. A metrics listener does not establish that application collectors belong to its registry.

## 4. Prove the changed guarantee

Distinguish instrumentation calls, collection, listener output, and remote export. Test the level the task promises. Record enabled and disabled behavior and cleanup where affected. Apply [Test policy](test-policy.md) before choosing a test target.

Done when reporting has an owner, instrumentation preserves caller context, sensitive values stay private, and the claimed observations have execution evidence.
