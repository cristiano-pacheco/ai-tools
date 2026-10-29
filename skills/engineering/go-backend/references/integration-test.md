# Integration test

Select for use-case durable effects, repository, transaction, migration, cache or
composed module guarantees. [Integration bootstrap](integration-bootstrap.md)
owns fixture selection and framework caveats. Use real controlled dependencies;
replace an uncontrolled provider at its port only when the project allows it.

Place `//go:build integration` suites under `test/integration/modules/<module>/<role>`,
mirroring production. Start/apply migrations once per suite; reset data and construct
fresh SUT/providers per scenario. Follow visible Arrange/Act/Assert. Assert output,
persisted state, promised effects and negative state on failure. Concurrency claims
need competing real connections; sequential callbacks do not prove lock behavior.

## Example: migrated raw operation and persistence suite

`test/integration/modules/order/usecase/order_get_usecase_test.go`. Following the
JBN suite shape, this uses real Bricks validation, GORM adapters, module migration
and the same concrete raw constructor registered by Fx. No DSN flag, manual schema,
ORM AutoMigrate or alternate production wiring is needed. The example module's
SQL has no external foreign keys, so its single owned migration path is complete.

```go
//go:build integration

package usecase_test

import (
	"context"
	"errors"
	"testing"

	"example.com/project/internal/modules/order/errs"
	"example.com/project/internal/modules/order/model"
	"example.com/project/internal/modules/order/repository"
	"example.com/project/internal/modules/order/usecase"
	"example.com/project/internal/modules/order/validator"
	"example.com/project/internal/shared/database"
	"github.com/cristiano-pacheco/bricks/pkg/itestkit"
	bricksvalidator "github.com/cristiano-pacheco/bricks/pkg/validator"
	"github.com/stretchr/testify/suite"
	"gorm.io/gorm"
)

type OrderGetUseCaseTestSuite struct {
	suite.Suite
	kit        *itestkit.ITestKit
	db         *database.ProjectDB
	repository *repository.OrderRepository
	sut        *usecase.OrderGetUseCase
}

func TestOrderGetUseCaseSuite(t *testing.T) { suite.Run(t, new(OrderGetUseCaseTestSuite)) }

func (s *OrderGetUseCaseTestSuite) SetupSuite() {
	cfg := itestkit.DefaultConfig()
	cfg.MigrationsPath = "file://internal/modules/order/migration"
	cfg.Database, cfg.User, cfg.Password = "project_test", "project_test", "project_test"
	s.kit = itestkit.New(cfg)
	s.T().Cleanup(s.kit.Cleanup)
	s.Require().NoError(s.kit.StartPostgres())
	s.Require().NoError(s.kit.RunMigrations())
	s.kit.DB().TranslateError = true
	s.db = &database.ProjectDB{DB: s.kit.DB()}
}

func (s *OrderGetUseCaseTestSuite) SetupTest() {
	s.kit.TruncateTables(s.T())
	inputValidator, err := bricksvalidator.New()
	s.Require().NoError(err)
	s.repository = repository.NewOrderRepository(s.db)
	s.sut = usecase.NewOrderGetUseCase(s.repository, inputValidator, validator.NewOrderAccessValidator())
}

func (s *OrderGetUseCaseTestSuite) TestExecuteReturnsOwnedOrder() {
	// Arrange
	ctx := context.Background()
	order, err := s.repository.Create(ctx, model.OrderModel{OwnerID: 7, Status: "pending"})
	s.Require().NoError(err)
	// Act
	output, err := s.sut.Execute(ctx, usecase.OrderGetInput{ID: order.ID, ActorID: 7})
	// Assert
	s.Require().NoError(err)
	s.Equal(order.ID, output.ID)
	s.Equal("pending", output.Status)
}

func (s *OrderGetUseCaseTestSuite) TestExecuteRejectsAnotherOwner() {
	// Arrange
	ctx := context.Background()
	order, err := s.repository.Create(ctx, model.OrderModel{OwnerID: 7, Status: "pending"})
	s.Require().NoError(err)
	// Act
	output, err := s.sut.Execute(ctx, usecase.OrderGetInput{ID: order.ID, ActorID: 8})
	// Assert
	s.ErrorIs(err, errs.ErrForbidden)
	s.Equal(usecase.OrderGetOutput{}, output)
	stored, loadErr := s.repository.FindByID(ctx, order.ID)
	s.Require().NoError(loadErr)
	s.Equal(uint64(7), stored.OwnerID)
}

func (s *OrderGetUseCaseTestSuite) TestUpdateWritesEmptyAndNull() {
	// Arrange
	ctx := context.Background()
	note := "initial"
	order, err := s.repository.Create(ctx, model.OrderModel{OwnerID: 7, Status: "pending", Notes: &note})
	s.Require().NoError(err)
	// Act
	empty := ""
	order.Notes = &empty
	updated, err := s.repository.Update(ctx, order)
	// Assert
	s.Require().NoError(err)
	s.Require().NotNil(updated.Notes)
	s.Equal("", *updated.Notes)
	// Arrange
	updated.Notes = nil
	// Act
	cleared, err := s.repository.Update(ctx, updated)
	// Assert
	s.Require().NoError(err)
	s.Nil(cleared.Notes)
}

func (s *OrderGetUseCaseTestSuite) TestTransactionRollsBack() {
	// Arrange
	ctx := context.Background()
	rejected := errors.New("reject second required step")
	// Act
	err := s.repository.WithTX(ctx, func(tx *gorm.DB) error {
		if _, err := s.repository.CreateTX(ctx, tx, model.OrderModel{OwnerID: 7, Status: "pending"}); err != nil {
			return err
		}
		return rejected
	})
	// Assert
	s.ErrorIs(err, rejected)
	var count int64
	s.Require().NoError(s.db.WithContext(ctx).Model(&model.OrderModel{}).Count(&count).Error)
	s.Zero(count)
}
```

Add absence, duplicate constraint, valid commit/reload, protected transition and
true contention scenarios when those are changed guarantees. Do not grow a
read-only query test into every persistence test because this recipe shows them.
For a repository-owned change, put its scenarios under the mirrored `repository`
path; the combined example demonstrates fixture reuse, not a mandatory grouping.

## Multi-module embedded migrations

`test/integration/fixture/migration.go`. Use this variation **instead of**
`kit.RunMigrations` when the suite needs the full production module stack.
The baseline kit does not export its migration URL. `gorm.io/driver/postgres`
uses pgx/stdlib; obtain its real config and build an escaped PostgreSQL URL,
then apply the same embedded runner. If the actual driver changes, adapt this
bridge to its real API rather than parsing a password-bearing DSN manually.

```go
//go:build integration

package fixture

import (
	"context"
	"errors"
	"fmt"
	"net"
	"net/url"
	"strconv"

	bricksmigration "github.com/cristiano-pacheco/bricks/pkg/migration"
	"github.com/jackc/pgx/v5/stdlib"
	"gorm.io/gorm"
)

func RunMigrations(ctx context.Context, db *gorm.DB, files []bricksmigration.FileSystem) error {
	pool, err := db.DB()
	if err != nil {
		return err
	}
	connection, err := pool.Conn(ctx)
	if err != nil {
		return err
	}
	var migrationURL url.URL
	extractErr := connection.Raw(func(raw any) error {
		conn, ok := raw.(*stdlib.Conn)
		if !ok {
			return fmt.Errorf("integration connection must use pgx stdlib")
		}
		cfg := conn.Conn().Config()
		migrationURL = url.URL{
			Scheme: "postgres", User: url.UserPassword(cfg.User, cfg.Password),
			Host: net.JoinHostPort(cfg.Host, strconv.Itoa(int(cfg.Port))), Path: "/" + cfg.Database,
			RawQuery: url.Values{"sslmode": {"disable"}}.Encode(),
		}
		return nil
	})
	if err := errors.Join(extractErr, connection.Close()); err != nil {
		return err
	}
	return bricksmigration.NewRunner(files).Up(migrationURL.String())
}
```

The URL above is scoped to the kit's owned plaintext PostgreSQL container.
Production TLS, Unix sockets, search paths and credentials follow the real
configuration contract; this fixture is not a universal production DSN converter.
It closes the borrowed connection before the migration runner opens its own pool.
Pass the production module filesystems, including foreign-key owners, in full;
[Migration](migration.md) owns global version ordering.

Run the real integration command with Docker available; fail on required missing
infrastructure. A skipped/compile-only run is explicitly unrun, never acceptance
proof. Use the public decorated graph for decoration/translation claims; its
code/status assertions differ from raw pointer identity as [Error](error.md) explains.
