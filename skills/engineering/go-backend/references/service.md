# Service

## Classify before extracting

A service owns a focused reusable capability after ruling out acceptance rules,
representation conversion, persistence, and protocol/vendor adaptation. A name
like `Build`, `Check`, or `Load`, I/O, or several callers does not establish that
ownership. Loading can be service-owned while checks delegate to Validator and
conversion delegates to Mapper. Private helper bodies use the same test.

| Behavior | Owner |
| --- | --- |
| One public operation's policy and workflow | Usecase |
| Reusable acceptance/rejection, including external evidence | Validator |
| Convert supplied data, format representation, assemble DTO | Mapper |
| Persist/query | Repository |
| Remote-service protocol / third-party SDK | Client / Provider |
| Remaining reusable capability | Service |

## Recipe: pure capability

Put the type in `service/<name>_service.go`; return its concrete pointer from
`New<Name>Service`. Pure computation needs no request context, I/O telemetry,
configuration, or port for symmetry. Use one focused `Execute` for one
capability, or descriptive methods for a coherent family. Extract conversion
and validation instead of hiding them in `*_helpers.go` or `*_mapping.go`.

`internal/modules/identity/service/password_hash_service.go`. The identity
module owns this pure capability; an order flow does not acquire authentication
helpers merely because they appear in the service recipe.

```go
package service

import "golang.org/x/crypto/bcrypt"

type PasswordHashService struct{}

func NewPasswordHashService() *PasswordHashService { return &PasswordHashService{} }

func (s *PasswordHashService) Generate(password []byte) ([]byte, error) {
	return bcrypt.GenerateFromPassword(password, bcrypt.DefaultCost)
}

func (s *PasswordHashService) Compare(hash, password []byte) error {
	return bcrypt.CompareHashAndPassword(hash, password)
}
```

## Recipe: I/O-backed reusable capability

1. Define only the shared application data it actually needs in `dto` and a
   consumer-owned service interface in `port`. Keep SDK/protocol shapes private
   to the underlying provider/client.
2. The implementation holds consumed ports, asserts its own port, and returns
   a concrete pointer from its constructor. Context is first on I/O methods.
3. Delegate pure conversion to Mapper and evidence rules to Validator. Preserve
   caller cancellation, dependency errors, and the invoking operation's atomicity.
4. Follow the project's I/O span and logging contracts. Log at its established
   owner; do not create a second error-log/telemetry convention in a copied recipe.
5. Bind via Fx only where the capability is consumed. A service is not a default
   wrapper around every use-case/repository call.

## Example: service input and provider value

`internal/modules/order/dto/order_confirmation_dto.go`.

```go
package dto

type OrderConfirmation struct {
	OrderID   uint64
	Recipient string
}
type EmailMessage struct {
	To      string
	Subject string
	Body    string
}
```

`internal/modules/order/port/order_confirmation_service.go`.

```go
package port

import (
	"context"

	"example.com/project/internal/modules/order/dto"
)

type OrderConfirmationService interface {
	Execute(ctx context.Context, input dto.OrderConfirmation) error
}

type EmailProvider interface {
	Send(ctx context.Context, message dto.EmailMessage) error
}
```

`internal/modules/order/mapper/order_confirmation_mapper.go`.

```go
package mapper

import (
	"fmt"

	"example.com/project/internal/modules/order/dto"
)

func ToOrderConfirmationMessage(input dto.OrderConfirmation) dto.EmailMessage {
	return dto.EmailMessage{
		To: input.Recipient, Subject: "Order confirmation",
		Body: fmt.Sprintf("Order %d is confirmed", input.OrderID),
	}
}
```

`internal/modules/order/service/order_confirmation_service.go`. Extract this
capability only when application flows share it. Whether to send,
and whether success requires durable delivery, remain operation contracts.

```go
package service

import (
	"context"

	"example.com/project/internal/modules/order/dto"
	"example.com/project/internal/modules/order/mapper"
	"example.com/project/internal/modules/order/port"
)

type OrderConfirmationService struct{ emailProvider port.EmailProvider }

var _ port.OrderConfirmationService = (*OrderConfirmationService)(nil)

func NewOrderConfirmationService(provider port.EmailProvider) *OrderConfirmationService {
	return &OrderConfirmationService{emailProvider: provider}
}

func (s *OrderConfirmationService) Execute(ctx context.Context, input dto.OrderConfirmation) error {
	return s.emailProvider.Send(ctx, mapper.ToOrderConfirmationMessage(input))
}
```

*Check:* real reuse, one clear responsibility, private-helper ownership, concrete
constructor, port/assertion/Fx agreement, and preserved collaborator errors.
For isolated proof, use permitted port doubles; integration-only projects prove
behavior through public operations and real controlled adapters. Do not assert
tracing internals or log formatting as a substitute for behavior.
