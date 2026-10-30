# CLI data flow

Read for a business Cobra entrypoint, CLI input/output mapping or its operation
call. [Data flow](data-flow.md) owns the shared execution/ownership contract;
[CLI](cli.md) owns flags, process errors, lifecycle and infrastructure commands.

## Files and execution

A new business command has its entrypoint in `cmd/<noun>_<action>_command.go`.
`cmd/order_get_command.go` owns `NewOrderGetCommand` and its `RunE`. `cmd/root.go` owns
the root command; `RegisterOrderGetCommand` attaches the operation to that root.
A module's use case contains the business operation, regardless of its transport.

```text
app order:get --id 42
  |
  v
Cobra parses --id as uint64; checks arguments
  |
  v
cmd/order_get_command.go: RunE                 CLI ENTRYPOINT
  | cmd.Context() + trusted session -> actor 7
  | constructs OrderGetInput{ID: 42, ActorID: 7}
  v
usecase.OrderGetUseCase.Execute                APPLICATION OPERATION
  | validates the complete Input
  | calls injected OrderRepository.FindByID(ctx, 42)
  |   -> concrete repository -> GORM -> database
  |   <- OrderModel{ID: 42, OwnerID: 7, Status: "pending"}
  | calls injected OrderAccessValidator.Validate(7, 7)
  | creates OrderGetOutput{ID: 42, Status: "pending"}
  v
Output/error returns directly to RunE
  |
  v
RunE writes "42\tpending\n" to cmd.OutOrStdout(), returns writer error or nil
  |
  v
ExecuteContext returns; process owns diagnostic/exit status
```

The repository lookup precedes the access rule in this specific operation because
the owner comes from the stored record. This order is the operation's policy,
not a requirement that every validator follows persistence access.

## Complete command and registration

`cmd/order_get_command.go`. Replace the module import path. Trusted CLI authentication
supplies `CommandActorID`; the command does not accept an actor/tenant flag as
proof of identity. Its constructor returns `*cobra.Command`.

```go
package cmd

import (
	"context"
	"fmt"

	"example.com/project/internal/modules/order/usecase"
	"github.com/spf13/cobra"
)

type CommandActorID func(context.Context) (uint64, error)

func NewOrderGetCommand(orderGet *usecase.OrderGetUseCase, actorID CommandActorID) *cobra.Command {
	var orderID uint64
	command := &cobra.Command{
		Use:   "order:get",
		Short: "Show one order",
		Args:  cobra.NoArgs,
		RunE: func(cmd *cobra.Command, _ []string) error {
			actor, err := actorID(cmd.Context())
			if err != nil {
				return err
			}
			output, err := orderGet.Execute(cmd.Context(), usecase.OrderGetInput{
				ID:      orderID,
				ActorID: actor,
			})
			if err != nil {
				return err
			}
			_, err = fmt.Fprintf(cmd.OutOrStdout(), "%d\t%s\n", output.ID, output.Status)
			return err
		},
	}
	command.Flags().Uint64Var(&orderID, "id", 0, "Order identifier")
	return command
}

func RegisterOrderGetCommand(root *cobra.Command,
	operation *usecase.OrderGetUseCase,
	actorID CommandActorID,
) {
	root.AddCommand(NewOrderGetCommand(operation, actorID))
}
```

At bootstrap, call `RegisterOrderGetCommand` with the root, concrete
`*usecase.OrderGetUseCase` and trusted identity resolver. With those dependencies
in Fx, use `fx.Invoke`. Registration does not execute the operation. The executable
later calls `root.ExecuteContext(callerContext)`.

The business CLI graph needs its application dependencies, not an HTTP server.
[Fx](fx.md) defines concrete constructor registration. The example and its
[Command test](command-test.md) use the default direct operation. Only when
explicitly requested or when changing an already decorated operation, follow
[Usecase decorator](usecase-decorator.md) and adapt its consumer signature to the
published decorated contract; a decorated application alone does not select it.

## Success and rejection

| Situation | Execution stops at | Result |
| --- | --- | --- |
| `--id abc` | Cobra uint64 parser | RunE/use case are not invoked; process receives parse error |
| `--id 0` or omitted ID in this example | Use-case input validation | Returned validation error; no repository lookup |
| Session resolution fails | RunE before operation call | Original authentication error; no operation invocation |
| Actor 7 asks for actor 8's stored order | Use-case access validator | Rejection reaches RunE directly; no success output |
| Valid owned record | RunE after Output | One formatted line on the command's output writer |
| Output writer fails | RunE after operation completed | Writer error; do not execute the operation again |

RunE returns errors; it does not print duplicate diagnostics or call `os.Exit`.
An output failure after a successful write operation does not roll back its
committed effect. Retry/idempotency follows that operation's contract.

*Check:* file in `cmd`, root registration, caller context/trusted identity,
explicit Input, one public Execute call, and Output-only rendering. Apply
[Test policy](test-policy.md) to verification; use [Command test](command-test.md)
only when an explicit request or project contract requires command testing.
