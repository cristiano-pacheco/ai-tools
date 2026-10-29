# Unit test

Use the project's test boundary first. Default to local deterministic proof for a
mapper, enum, validator, or pure service; use real integration for persistence,
transaction, and full use-case effects. Isolated collaborator proof is permitted
only where the project allows doubles. Never replace integration-only rules.

Put tests beside implementation in an external `<package>_test` package unless
local tooling requires otherwise. Give each scenario a behavior name and clear
Arrange/Act/Assert separation. Cover success, each stable rejection, both sides
of thresholds, null/zero/empty distinctions, and dependency failure when relevant.
Use `errors.Is`/`errors.As` or the project's equivalent, not rendered-message
matching. Assert side-effect absence when rejection must precede I/O.

For collaborators, reuse generated project mocks or narrow controlled ports. A
fresh fixture/SUT per case prevents state leakage. Context matchers must not
assume one concrete implementation of `context.Context`. Do not assert span
internals, logger formatting, or private helper calls as a proxy for behavior.

The optional example below focuses on validation-before-I/O and is appropriate
only for a permitted isolated use-case boundary. It does not replace public-operation
integration proof for policy and persistence.

## Example: input validation proof

`internal/modules/order/usecase/order_get_usecase_test.go`. The concrete input
validator checks tags; the controlled repository makes any premature I/O fail.
The access validator is the named implementation from its recipe.

```go
package usecase_test

import (
	"context"
	"errors"
	"testing"

	"example.com/project/internal/modules/order/model"
	"example.com/project/internal/modules/order/usecase"
	"example.com/project/internal/modules/order/validator"
	bricksvalidator "github.com/cristiano-pacheco/bricks/pkg/validator"
	validation "github.com/go-playground/validator/v10"
)

type orderRepositoryFunc func(context.Context, uint64) (model.OrderModel, error)

func (f orderRepositoryFunc) FindByID(ctx context.Context, id uint64) (model.OrderModel, error) {
	return f(ctx, id)
}

func (f orderRepositoryFunc) Create(context.Context, model.OrderModel) (model.OrderModel, error) {
	return model.OrderModel{}, errors.New("unexpected create in read-only test")
}

func (f orderRepositoryFunc) Update(context.Context, model.OrderModel) (model.OrderModel, error) {
	return model.OrderModel{}, errors.New("unexpected update in read-only test")
}

func (f orderRepositoryFunc) Delete(context.Context, model.OrderModel) (model.OrderModel, error) {
	return model.OrderModel{}, errors.New("unexpected delete in read-only test")
}

func TestOrderGetRejectsInvalidInputBeforeIO(t *testing.T) {
	repository := orderRepositoryFunc(func(context.Context, uint64) (model.OrderModel, error) {
		t.Fatal("invalid input reached storage")
		return model.OrderModel{}, nil
	})
	inputValidator, validationErr := bricksvalidator.New()
	if validationErr != nil {
		t.Fatal(validationErr)
	}
	uc := usecase.NewOrderGetUseCase(repository, inputValidator, validator.NewOrderAccessValidator())
	for _, input := range []usecase.OrderGetInput{{ID: 0, ActorID: 7}, {ID: 42, ActorID: 0}} {
		output, err := uc.Execute(context.Background(), input)
		var failures validation.ValidationErrors
		if !errors.As(err, &failures) || output != (usecase.OrderGetOutput{}) {
			t.Fatalf("got %#v, %v", output, err)
		}
	}
}
```


*Check:* each assertion would catch the named behavioral regression, fixtures are
fresh, expected errors keep identity, and no infrastructure guarantee is claimed
from a controlled port.

## Example: enum acceptance and rejection

`internal/modules/order/enum/order_status_enum_test.go`. The constructor, not
only its string accessor, is the boundary establishing the accepted set.

```go
package enum_test

import (
	"errors"
	"testing"

	"example.com/project/internal/modules/order/enum"
	"example.com/project/internal/modules/order/errs"
)

func TestOrderStatusEnum(t *testing.T) {
	for _, literal := range []string{enum.OrderStatusPending, enum.OrderStatusConfirmed, enum.OrderStatusCanceled} {
		t.Run(literal, func(t *testing.T) {
			value, err := enum.NewOrderStatusEnum(literal)
			if err != nil || value.String() != literal {
				t.Fatalf("got %q, %v", value.String(), err)
			}
		})
	}
	t.Run("unknown is rejected", func(t *testing.T) {
		_, err := enum.NewOrderStatusEnum("unknown")
		if !errors.Is(err, errs.ErrInvalidOrderStatus) {
			t.Fatalf("unexpected rejection: %v", err)
		}
	})
}
```

## Example: conversion failure preserves classification and cause

`internal/modules/order/mapper/delivery_date_mapper_test.go`.

```go
package mapper_test

import (
	"errors"
	"testing"
	"time"

	"example.com/project/internal/modules/order/errs"
	"example.com/project/internal/modules/order/mapper"
)

func TestToDeliveryDate(t *testing.T) {
	t.Run("valid date", func(t *testing.T) {
		value, err := mapper.ToDeliveryDate("2026-10-29")
		if err != nil || value.Format("2006-01-02") != "2026-10-29" {
			t.Fatalf("got %v, %v", value, err)
		}
	})
	t.Run("invalid date preserves cause", func(t *testing.T) {
		_, err := mapper.ToDeliveryDate("2026-02-30")
		var parseError *time.ParseError
		if !errors.Is(err, errs.ErrInvalidDate) || !errors.As(err, &parseError) {
			t.Fatalf("lost error contract: %v", err)
		}
	})
}
```
