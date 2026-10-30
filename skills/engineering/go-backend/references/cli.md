# Cobra CLI

Use `github.com/spf13/cobra`. Inspect its pinned version and the project's root
command before adding a command. Return `*cobra.Command` from a constructor;
register it with `AddCommand` in existing composition. Keep flags local to that
command instance and use `RunE` for fallible execution.

## Recipe: business command

1. Establish command name, flags, argument count, output, and error/exit contract.
   Configure Cobra argument validation and flag parsing for boundary syntax.
2. In `RunE`, map parsed values into one explicit use-case input. Resolve caller
   identity through the existing trusted session/configuration integration.
3. Call one use case with `cmd.Context()`. Use `cmd.OutOrStdout()` for data and
   `cmd.ErrOrStderr()` for diagnostics. Return application and writer errors.
4. Register the command and call `ExecuteContext` at the process boundary with
   cancellation. That boundary owns error printing and exit status. Configure
   `SilenceErrors`/`SilenceUsage` there to avoid duplicate diagnostics; preserve
   existing help and usage behavior.
5. Read [Use case](usecase.md) for a new operation and [Mapper](mapper.md)
   for affected conversions. Read [Fx](fx.md) when graph registration or bindings
   change, and [Runtime](runtime.md) for affected resource/lifecycle behavior.

Business policy, transactions, storage, and provider calls stay behind the use
case. Required business fields are validated there for every transport. Cobra
may also reject missing flags when that is the established CLI contract.

## Recipe: infrastructure command

A server command runs the process lifecycle; a migration command invokes its
runner. Both use Cobra `RunE` and [runtime](runtime.md), with no business-use-case
wrapper. Schema changes select [Model](model.md); a help-only edit does not.

*Check:* execute the registered Cobra command with `SetArgs`, injectable
`SetOut`/`SetErr`, and `ExecuteContext`. Prove argument parsing, output, error
identity, cancellation, and registration. Test process exit behavior separately
when it changes; `RunE` returning an error does not itself exit the process.

## Implementation example

[CLI data flow](data-flow-cli.md) owns the complete `cmd/order_get_command.go` example,
root registration and concrete Input/Output trace. Read it when creating/changing
a business entrypoint or clarifying that boundary; existing verified command
policy does not require loading unrelated HTTP or storage examples.

## Example: server process command

`cmd/server_command.go`. The caller supplies the required real Fx modules; the command
starts/stops their graph instead of wrapping lifecycle in a business use case.
Its parent executes with a signal-cancelled context. Each resource owns its hooks
and any cleanup needed for its own failed startup.

```go
package cmd

import (
	"context"
	"errors"
	"time"

	"github.com/spf13/cobra"
	"go.uber.org/fx"
)

func NewServerCommand(options ...fx.Option) *cobra.Command {
	return &cobra.Command{
		Use: "server", Args: cobra.NoArgs,
		RunE: func(command *cobra.Command, _ []string) (runErr error) {
			app := fx.New(options...)
			if err := app.Err(); err != nil {
				return err
			}
			startCtx, cancelStart := context.WithTimeout(command.Context(), 10*time.Second)
			err := app.Start(startCtx)
			cancelStart()
			if err != nil {
				return err
			}
			defer func() {
				stopCtx, cancelStop := context.WithTimeout(context.Background(), 10*time.Second)
				defer cancelStop()
				runErr = errors.Join(runErr, app.Stop(stopCtx))
			}()
			<-command.Context().Done()
			return nil
		},
	}
}
```

The fresh bounded shutdown context is intentional: the running command context
is already cancelled. Register the command at the process root. A migration
command similarly resolves/runs its actual migration runner, returns failures,
and closes its graph; it does not instantiate an HTTP server or business operation.
Read [Command test](command-test.md) for changed boundary proof.
