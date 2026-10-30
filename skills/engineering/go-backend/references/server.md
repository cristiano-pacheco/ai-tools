# Server bootstrap

Read when creating/changing the server process graph, root command or its
base platform configuration. [CLI](cli.md) owns the Cobra lifecycle runner.

## Default server graph

`cmd/application.go`. This graph mirrors the JBN approach: shared infrastructure
once, business modules once, HTTP lifecycle once. A project's actual module list
and authentication integration replace the example choices. Only add Redis when
an operation needs it. Optional resources remain behind consumers.

```go
package cmd

import (
	"example.com/project/internal/modules/order"
	"example.com/project/internal/shared/database"
	"github.com/cristiano-pacheco/bricks/pkg/http/response"
	brickschi "github.com/cristiano-pacheco/bricks/pkg/http/server/chi"
	"github.com/cristiano-pacheco/bricks/pkg/i18n"
	"github.com/cristiano-pacheco/bricks/pkg/logger"
	"github.com/cristiano-pacheco/bricks/pkg/metrics"
	"github.com/cristiano-pacheco/bricks/pkg/otel/trace"
	"github.com/cristiano-pacheco/bricks/pkg/validator"
	"go.uber.org/fx"
)

var ServerModule = fx.Module("server",
	logger.Module, validator.Module, response.Module,
	metrics.Module, i18n.Module, trace.Module,
	database.Module, order.Module, brickschi.Module,
)
```

`cmd/root.go`. The caller supplies trusted identity resolution from real
middleware/session infrastructure. There is no fabricated default actor.
[CLI](cli.md) owns `NewServerCommand` and cancellation/shutdown behavior.

```go
package cmd

import (
	"example.com/project/internal/modules/order"
	"example.com/project/internal/modules/order/http/chi/handler"
	"github.com/spf13/cobra"
	"go.uber.org/fx"
)

func NewRootCommand(actorID handler.ActorID) *cobra.Command {
	root := &cobra.Command{Use: "app", SilenceErrors: true, SilenceUsage: true}
	root.AddCommand(
		NewServerCommand(ServerModule, fx.Supply(actorID)),
		NewMigrateCommand(order.Module),
	)
	return root
}
```

The executable supplies a signal-cancelled context to `ExecuteContext`, prints
one returned error and sets the process exit status. Business commands consume
published operations; lifecycle and migration commands have no business-use-case
wrapper. Fx providers are lazy: `brickschi.Module` forces server construction,
which reaches grouped routes, handlers, concrete use cases and their dependencies.
The default graph has no use-case decorator module. Add its module/publication
only for an explicit request or an existing decorated use case being changed;
other decorated operations do not change the default for a new use case.

## Base configuration

`config/base.yaml`. This contains the actual fields expected by v0.1.21 modules,
not settings copied from a newer checkout. HTTP ports are distinct and required;
this version always starts a separate metrics listener. OTel is initialized once
with export disabled locally. Supply real database credentials externally.

```yaml
app:
  database:
    host: localhost
    port: 5432
    name: project
    user: "env://DATABASE_USER"
    password: "env://DATABASE_PASSWORD"
    sslmode: false
    maxopenconnections: 10
    maxidleconnections: 5
  logger:
    level: info
    encoding: json
    outputpaths: [stdout]
    erroroutputpaths: [stderr]
  http:
    port: 8080
    metricsport: 9090
    readtimeout: 15s
    writetimeout: 15s
    idletimeout: 60s
    shutdowntimeout: 10s
  open-telemetry:
    app_name: project
    app_version: local
    trace_enabled: false
  i18n:
    language: en
```

Validate required project secrets/pool bounds at startup. A config file alone
does not prove valid required values; [Configuration](configuration.md) owns
loader semantics. A newer resolved version may support listener addresses,
disabling metrics, synchronous binds and SQLite; inspect that version before
using those options. `/healthz` in this baseline is a static HTTP response,
not a database/Redis readiness probe.


*Check:* one process owner for each platform module, real trusted identity,
reachable routes/public operations, matching config fields and actual readiness
evidence. Migration and Redis setup load only for those capabilities.
