# Command test

Use the closest Cobra acceptance boundary. Prove changed flags/args map to the public
input, malformed syntax fails before application execution, caller context reaches
one operation, output goes to the declared writer, and errors remain classifiable.
The operation's integration suite proves policy/persistence rather than repeating
its full matrix through Cobra. Do not introduce a use-case interface solely to mock
its concrete type; use the existing factory/replacement/acceptance boundary.

For server/migration commands, prove module selection, runner invocation, startup
failure, cancellation, and cleanup at their composition boundary. No business-use-case
call is expected for these infrastructure commands. Start real infrastructure
only when the changed guarantee needs it.

## Example: registered business command

`cmd/order_get_test.go`. The embedded port is an
unused fallback: an unexpected write has no implementation and fails the test;
the only supplied behavior is the read needed by this boundary scenario.

```go
package cmd_test

import (
	"bytes"
	"context"
	"testing"

	"example.com/project/cmd"
	"example.com/project/internal/modules/order/model"
	"example.com/project/internal/modules/order/port"
	"example.com/project/internal/modules/order/usecase"
	"example.com/project/internal/modules/order/validator"
	bricksvalidator "github.com/cristiano-pacheco/bricks/pkg/validator"
	"github.com/spf13/cobra"
)

type readOnlyRepository struct {
	port.OrderRepository
	calls   int
	context context.Context
}

func (r *readOnlyRepository) FindByID(ctx context.Context, id uint64) (model.OrderModel, error) {
	r.calls++
	r.context = ctx
	return model.OrderModel{ID: id, OwnerID: 7, Status: "pending"}, nil
}

func TestRegisteredCobraCommand(t *testing.T) {
	inputValidator, validationErr := bricksvalidator.New()
	if validationErr != nil {
		t.Fatal(validationErr)
	}
	repository := &readOnlyRepository{}
	uc := usecase.NewOrderGetUseCase(repository, inputValidator, validator.NewOrderAccessValidator())
	root := &cobra.Command{Use: "app"}
	cmd.RegisterOrderGetCommand(root, uc, func(context.Context) (uint64, error) { return 7, nil })
	var stdout, stderr bytes.Buffer
	root.SetOut(&stdout)
	root.SetErr(&stderr)
	root.SetArgs([]string{"order:get", "--id", "42"})
	type contextKey struct{}
	ctx := context.WithValue(context.Background(), contextKey{}, "caller")
	if err := root.ExecuteContext(ctx); err != nil {
		t.Fatal(err)
	}
	if repository.calls != 1 || repository.context.Value(contextKey{}) != "caller" {
		t.Fatal("expected one operation lookup with caller context")
	}
	if stdout.String() != "42\tpending\n" || stderr.Len() != 0 {
		t.Fatalf("unexpected output: stdout=%q stderr=%q", stdout.String(), stderr.String())
	}
}

func TestRegisteredCommandRejectsMalformedIDBeforeInvocation(t *testing.T) {
	inputValidator, err := bricksvalidator.New()
	if err != nil {
		t.Fatal(err)
	}
	repository := &readOnlyRepository{}
	uc := usecase.NewOrderGetUseCase(repository, inputValidator, validator.NewOrderAccessValidator())
	root := &cobra.Command{Use: "app", SilenceErrors: true, SilenceUsage: true}
	cmd.RegisterOrderGetCommand(root, uc, func(context.Context) (uint64, error) {
		t.Fatal("malformed flag reached RunE")
		return 0, nil
	})
	root.SetArgs([]string{"order:get", "--id", "abc"})
	if err := root.ExecuteContext(context.Background()); err == nil {
		t.Fatal("expected flag parse error")
	}
	if repository.calls != 0 {
		t.Fatal("malformed flag reached storage")
	}
}
```

*Check:* registered path, affected success/error/parse branches, writers, context,
unchanged policy boundary, and no dependency bootstrapped only for command symmetry.
Use a subprocess when actual process exit/signal behavior is the changed contract.
