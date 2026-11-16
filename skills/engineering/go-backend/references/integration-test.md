# Integration test

Apply [Test policy](test-policy.md) first. Test usecase or service public operations by default. Exercise repositories, transactions, migrations, and caches through those operations rather than separate suites unless the user or project explicitly requires them.

## 1. Build the real fixture

Select the required stack through [Integration bootstrap](integration-bootstrap.md). Use production SQL and controlled real dependencies. Replace an uncontrolled provider at its port only when the project permits it.

Keep fixture mechanics outside each behavior scenario. For Bricks containers, cleanup, and migration APIs, follow [Bricks handoff](bricks.md). Do not copy those framework tutorials into application test policy.

## 2. Construct the intended operation

Use the same concrete constructor and real adapters as production. When proving runtime publication, use the production module graph and resolve its actual public consumer. Direct execution is the default. Only selected decorator work requires the decorated publication.

Start and migrate once per serial suite when appropriate. Reset state and construct fresh operations per scenario. Keep environment-changing suites nonparallel. Place tests under `test/integration/modules/<module>/usecase` or `service` with the corresponding role basename and `//go:build integration`.

## 3. Assert through the public boundary

This focused scenario assumes the fixture supplies a migrated `*gorm.DB` and a real `*usecase.OrderGetUseCase`. It shows assertions, not container setup. Call it from the application's test after opening that fixture.

```go
package usecase_test

import (
    "context"
    "errors"
    "testing"

    "example.com/project/internal/modules/order/errs"
    "example.com/project/internal/modules/order/model"
    "example.com/project/internal/modules/order/usecase"
    "gorm.io/gorm"
)

func checkOrderGetRejectsAnotherOwner(t *testing.T, db *gorm.DB, operation *usecase.OrderGetUseCase) {
    t.Helper()
    // Arrange
    ctx := context.Background()
    order := model.OrderModel{OwnerID: 7, Status: "pending"}
    if err := db.WithContext(ctx).Create(&order).Error; err != nil {
        t.Fatal(err)
    }
    // Act
    output, err := operation.Execute(ctx, usecase.OrderGetInput{ID: order.ID, ActorID: 8})
    // Assert
    if !errors.Is(err, errs.ErrForbidden) || output != (usecase.OrderGetOutput{}) {
        t.Fatalf("got %#v, %v", output, err)
    }
    var stored model.OrderModel
    if err := db.WithContext(ctx).First(&stored, order.ID).Error; err != nil {
        t.Fatal(err)
    }
    if stored.OwnerID != 7 || stored.Status != "pending" {
        t.Fatalf("rejected operation changed storage: %#v", stored)
    }
}
```

Setup and storage inspection may use GORM directly. The action under test invokes the use case. Do not label a direct repository update or transaction callback as use-case integration proof.

Add success, absence, invalid input, constraints, commit, and rollback scenarios only when those are changed guarantees. For rollback, invoke the operation that owns the required atomic steps and assert no partial durable state. Concurrency claims require competing real connections, not sequential callbacks.

## 4. Run and report

Run the project's actual integration command with required infrastructure available. Fail rather than silently skip a required dependency. Record the command, observed behavior, and failed or unrun checks. Compilation and graph validation do not establish runtime behavior.

Done when each changed guarantee passes at its allowed public boundary with isolated real dependencies and visible negative-state assertions.
