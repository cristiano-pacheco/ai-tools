# Migration command

Read when creating/changing the Cobra migration process, its filesystem
collection or runner invocation. [Migration](migration.md) owns SQL and assets.

## Migration command: reuse assets, start only the runner

`cmd/migrate.go`. The same business module contributes SQL through its real Fx
provider. The command resolves those assets and config without constructing its
unused repository, HTTP handler, decorators, database wrapper or HTTP server.
The runner owns its transient migration connections. Configuration/schema errors
reach Cobra `RunE` as errors; there is no process exit inside a constructor.

```go
package cmd

import (
	"net"
	"net/url"
	"strconv"

	sharedmigration "example.com/project/internal/shared/migration"
	bricksconfig "github.com/cristiano-pacheco/bricks/pkg/config"
	bricksdatabase "github.com/cristiano-pacheco/bricks/pkg/database"
	bricksmigration "github.com/cristiano-pacheco/bricks/pkg/migration"
	"github.com/spf13/cobra"
	"go.uber.org/fx"
)

func NewMigrateCommand(modules ...fx.Option) *cobra.Command {
	return &cobra.Command{
		Use: "migrate", Args: cobra.NoArgs,
		RunE: func(command *cobra.Command, _ []string) error {
			if err := command.Context().Err(); err != nil {
				return err
			}
			options := []fx.Option{
				sharedmigration.Module,
				bricksconfig.Provide[bricksdatabase.Config]("app.database"),
				fx.Invoke(func(runner *bricksmigration.Runner, loaded bricksconfig.Config[bricksdatabase.Config]) error {
					cfg := loaded.Get()
					if err := cfg.Validate(); err != nil {
						return err
					}
					sslmode := "disable"
					if cfg.SSLMode {
						sslmode = "require"
					}
					timezone := cfg.TimeZone
					if timezone == "" {
						timezone = "UTC"
					}
					query := url.Values{"sslmode": {sslmode}, "TimeZone": {timezone}}
					if cfg.SSLCert != "" {
						query.Set("sslcert", cfg.SSLCert)
					}
					if cfg.SSLKey != "" {
						query.Set("sslkey", cfg.SSLKey)
					}
					if cfg.SSLRootCert != "" {
						query.Set("sslrootcert", cfg.SSLRootCert)
					}
					if cfg.SearchPath != "" {
						query.Set("search_path", cfg.SearchPath)
					}
					if cfg.ApplicationName != "" {
						query.Set("application_name", cfg.ApplicationName)
					}
					address := url.URL{
						Scheme: "postgres", User: url.UserPassword(cfg.User, cfg.Password),
						Host: net.JoinHostPort(cfg.Host, strconv.Itoa(int(cfg.Port))), Path: "/" + cfg.Name,
						RawQuery: query.Encode(),
					}
					return runner.Up(address.String())
				}),
			}
			options = append(options, modules...)
			return fx.New(options...).Err()
		},
	}
}
```

This baseline `Runner.Up` has no context argument; checking command cancellation
before starting does not make an in-flight migration cancellable. Do not claim
that guarantee. Preserve any project's established timeout/lock configuration
and migration-only module composition. The URL construction deliberately escapes
credentials; the baseline `Config.PostgresDSN` formats them without URL escaping.


*Check:* production SQL contributions, globally ordered versions, escaped
connection parameters, failures returned to Cobra and no HTTP/resource startup
solely to apply migrations.
