# Unit test

Apply [Test policy](test-policy.md) first. By default, unit test dependency-free
behavior without mocks or test doubles; usecase and service tests are integration
tests, including for pure services.

Put tests beside implementation in an external `<package>_test` package unless
local tooling requires otherwise. Give each scenario a behavior name and clear
Arrange/Act/Assert separation. Cover success, each stable rejection, both sides
of thresholds, null/zero/empty distinctions, and dependency failure when relevant.
Use `errors.Is`/`errors.As` or the project's equivalent, not rendered-message
matching. Assert side-effect absence when rejection must precede I/O.

A fresh fixture/SUT per case prevents state leakage. Do not assert span
internals, logger formatting, or private helper calls as a proxy for behavior.

Usecase input-validation proof belongs to the public-operation integration suite
by default. Only an explicit request or project contract selects a controlled-port
unit test for that target. Such a test does not replace real-adapter proof.

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
