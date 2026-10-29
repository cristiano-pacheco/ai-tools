# Usecase decorator test

Read for public operation publication, decorator configuration/effects, or its
composition proof. [Usecase decorator](usecase-decorator.md) owns production
contracts; [Integration test](integration-test.md) owns the migrated PostgreSQL
suite. Reuse that suite rather than create another container test setup.

## Proof boundary

Resolve the public generic operations through the production `order.Module`,
not a test-only call to `Wrap`. The example uses real repositories, validation,
i18n and factory. A recording metrics implementation isolates process-global
Prometheus registration and observes exactly-once outcomes; it does not prove
Prometheus export. Tracing is disabled in this focused graph; traced context,
OTLP export and logger output require their own affected-boundary evidence.

`test/integration/modules/order/usecase/order_decorator_test.go`. These methods
extend `OrderGetUseCaseTestSuite` from Integration test. Its runner discovers
them, and its normal `SetupTest` resets real persistence before each test.
The config fixture loads through the actual Bricks loader. Tests remain
sequential because config selection uses process environment.

```go
//go:build integration

package usecase_test

import (
	"context"
	"fmt"
	"os"
	"path/filepath"
	"testing"
	"time"

	"example.com/project/internal/modules/order"
	"example.com/project/internal/modules/order/errs"
	"example.com/project/internal/modules/order/usecase"
	brickserrs "github.com/cristiano-pacheco/bricks/pkg/errs"
	"github.com/cristiano-pacheco/bricks/pkg/i18n"
	"github.com/cristiano-pacheco/bricks/pkg/logger"
	"github.com/cristiano-pacheco/bricks/pkg/metrics"
	"github.com/cristiano-pacheco/bricks/pkg/ucdecorator"
	bricksvalidator "github.com/cristiano-pacheco/bricks/pkg/validator"
	"github.com/stretchr/testify/require"
	"go.uber.org/fx"
)

type recordingOrderMetrics struct {
	duration map[string]int
	success  map[string]int
	failure  map[string]int
}

func (m *recordingOrderMetrics) ObserveDuration(name string, _ time.Duration) { m.duration[name]++ }
func (m *recordingOrderMetrics) IncSuccess(name string)                       { m.success[name]++ }
func (m *recordingOrderMetrics) IncError(name string)                         { m.failure[name]++ }

type publishedOrderOperations struct {
	get    ucdecorator.UseCase[usecase.OrderGetInput, usecase.OrderGetOutput]
	create ucdecorator.UseCase[usecase.OrderCreateInput, usecase.OrderCreateOutput]
	rawGet *usecase.OrderGetUseCase
}

func (s *OrderGetUseCaseTestSuite) publishedOperations(t *testing.T, enabled bool) (publishedOrderOperations, *recordingOrderMetrics) {
	t.Helper()
	directory := t.TempDir()
	configuration := fmt.Sprintf(`app:
  ucdecorator:
    enabled: %t
    debug_mode: false
    logging: true
    metrics: true
    tracing: false
    translation: true
  i18n:
    language: pt_BR
`, enabled)
	require.NoError(t, os.WriteFile(filepath.Join(directory, "base.yaml"), []byte(configuration), 0600))
	t.Setenv("APP_CONFIG_DIR", directory)
	t.Setenv("APP_ENV", "test")
	cfg := logger.DefaultConfig()
	cfg.OutputPaths, cfg.ErrorOutputPaths = nil, nil
	log, err := logger.New(cfg)
	require.NoError(t, err)
	t.Cleanup(func() { require.NoError(t, log.Sync()) })
	observed := &recordingOrderMetrics{duration: map[string]int{}, success: map[string]int{}, failure: map[string]int{}}
	var operations publishedOrderOperations
	app := fx.New(fx.NopLogger,
		order.Module, bricksvalidator.Module, i18n.Module, ucdecorator.Module,
		fx.Supply(s.db),
		fx.Supply(fx.Annotate(log, fx.As(new(logger.Logger)))),
		fx.Supply(fx.Annotate(observed, fx.As(new(metrics.UseCaseMetrics)))),
		fx.Invoke(func(
			get ucdecorator.UseCase[usecase.OrderGetInput, usecase.OrderGetOutput],
			create ucdecorator.UseCase[usecase.OrderCreateInput, usecase.OrderCreateOutput],
			rawGet *usecase.OrderGetUseCase,
		) {
			operations = publishedOrderOperations{get: get, create: create, rawGet: rawGet}
		}),
	)
	require.NoError(t, app.Err())
	startCtx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	require.NoError(t, app.Start(startCtx))
	t.Cleanup(func() {
		stopCtx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()
		require.NoError(t, app.Stop(stopCtx))
	})
	return operations, observed
}

func (s *OrderGetUseCaseTestSuite) TestPublicDecoratorPreservesPersistenceAndObservesOnce() {
	// Arrange
	operations, observed := s.publishedOperations(s.T(), true)
	ctx := context.Background()
	// Act
	created, err := operations.create.Execute(ctx, usecase.OrderCreateInput{ActorID: 7})
	// Assert
	s.Require().NoError(err)
	stored, err := s.repository.FindByID(ctx, created.ID)
	s.Require().NoError(err)
	s.Equal(created.ID, stored.ID)
	s.Equal("pending", stored.Status)
	s.Equal(1, observed.success["order_create"])
	s.Equal(1, observed.duration["order_create"])
	// Arrange
	input := usecase.OrderGetInput{ID: created.ID, ActorID: 8}
	// Act
	output, err := operations.get.Execute(ctx, input)
	// Assert
	var coded *brickserrs.Error
	s.Require().ErrorAs(err, &coded)
	s.Equal(errs.ErrForbidden.Code, coded.Code)
	s.Equal(errs.ErrForbidden.Status, coded.Status)
	s.Equal("Acesso ao pedido negado", coded.Message)
	s.NotErrorIs(err, errs.ErrForbidden)
	s.Equal(usecase.OrderGetOutput{}, output)
	s.Equal(1, observed.failure["order_get"])
	s.Equal(1, observed.duration["order_get"])
	s.Zero(observed.success["order_get"])
}

func (s *OrderGetUseCaseTestSuite) TestDisabledDecoratorPublishesRawInstance() {
	// Arrange
	operations, observed := s.publishedOperations(s.T(), false)
	s.Same(operations.rawGet, operations.get)
	// Act
	_, err := operations.get.Execute(context.Background(), usecase.OrderGetInput{ID: 999, ActorID: 7})
	// Assert
	s.ErrorIs(err, errs.ErrOrderNotFound)
	s.Empty(observed.success)
	s.Empty(observed.failure)
	s.Empty(observed.duration)
}
```

## Extend only the changed guarantee

- A flag change covers that flag enabled/disabled through the same real module.
  Test `enabled: true` with all individual flags false when changing that profile;
  it should still publish the raw instance.
- An input-validation error stays recognizable as validation errors; translation
  only reconstructs recognized catalog errors. Test no storage mutation on rejection.
- A caller cancellation test uses a canceled/deadline context and verifies the
  actual returned cause through real adapters, accounting for typed error translation.
- Trace changes assert child/parent relationship and cancellation propagation
  through a controlled tracer; plain context pointer equality is not the contract.
- A naming/duplicate-wrap regression asserts exactly one observation for each
  invocation and the expected operation label. Do not assert timing values or
  private wrapper type names.

*Check:* production public keys resolve, two operations coexist, persistence
survives the chain, translated code/status match, observations occur once and
disabling decoration preserves raw identity without metrics side effects.
