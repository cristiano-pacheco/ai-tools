# Observability

Read for log/span/metric behavior or operation decoration, not every business
method edit. Use Bricks `logger`, `metrics` and `otel/trace` for the selected
observability needs; register consumed process-wide modules once at the
composition owner. Direct use cases are the default: decorator logging, metrics,
tracing and translation are not implicit guarantees.

Only an explicit decorator request or modification of an existing decorated
use case selects `ucdecorator`. In that branch, the decorated profile owns
generic operation success/failure logs, duration, success/error counters,
application span and error translation; keep that chain out of `Execute`.
The framework logger wraps Zap; its `Field` and field helpers
are not slog attributes. The HTTP server separately uses its own slog logger and
Chi request middleware; installing `logger.Module` does not automatically bridge
those loggers.

## Adapter span

`internal/modules/order/repository/order_exists_repository.go`. This optional repository
method illustrates a contextual I/O span; add its port method only when consumed.

```go
package repository

import (
	"context"

	"example.com/project/internal/modules/order/model"
	"github.com/cristiano-pacheco/bricks/pkg/otel/trace"
)

func (r *OrderRepository) Exists(ctx context.Context, id uint64) (bool, error) {
	ctx, span := trace.Span(ctx, "OrderRepository.Exists")
	defer span.End()
	var count int64
	err := r.db.WithContext(ctx).Model(&model.OrderModel{}).Where("id = ?", id).Count(&count).Error
	if err != nil {
		span.RecordError(err)
		return false, err
	}
	return count > 0, nil
}
```

Propagate the derived context to queries/downstream calls. Follow this pattern
for I/O methods in repository, client, provider, cache and I/O-backed service;
pure mappers and pure validators require no span/logger. A span does not replace
a contract test or guarantee that HTTP trace context was extracted; verify the
actual transport instrumentation when distributed propagation is in scope.

The baseline metrics constructor registers collectors in Prometheus's global
registry. Repeated process graphs in one test process can fail duplicate
registration; use the project's controlled registry/test metrics replacement,
or isolated processes. Do not reset global collectors in unrelated tests.
Tracing also owns global initialization and shutdown; concurrent graph tests
must not pretend those are per-module resources.

Do not log raw operation inputs/outputs, credentials, tokens or provider payloads.
Record an unexpected returned failure at the established reporting owner once;
use adapter spans for additional technical location without duplicate error logs.
For the default direct profile, define or preserve its error-reporting owner
rather than assuming a decorator exists. Read [Usecase decorator](usecase-decorator.md)
only for the explicitly selected or existing decorated branch.

## Trace configuration in the baseline

`trace.Module` reads `app.open-telemetry`; the example base omits `exporter_type`
and uses the framework's gRPC default. In v0.1.21 `ExporterType` wraps a private
value with no text-unmarshal method; a YAML string is not evidence that the
loader can construct it. For explicit HTTP export, build the value with
`trace.NewExporterType(trace.ExporterTypeHTTP)` and initialize at the shared
lifecycle owner with `trace.Initialize`/`Shutdown`, replacing the built-in trace
module rather than initializing twice. Verify loading and export for that profile.
A zero sample rate is normalized to 0.01 in this baseline; disable export with
`trace_enabled: false` rather than claiming zero disables tracing.
