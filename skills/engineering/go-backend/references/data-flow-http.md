# HTTP data flow

Read for an HTTP business entrypoint or request/operation/response mapping.
[Data flow](data-flow.md) owns the shared contract. [HTTP handler](http-handler.md)
owns transport policy; [HTTP router](http-router.md) owns actual method/path
registration and its Bricks `Route` contribution.

## Registration is not execution

At bootstrap, Fx constructs the handler and its concrete use case. The module
router implements `brickschi.Route.Setup(*Server)`, registering
`GET /api/v1/orders/{id}` against `HandleGetOrder`. Bricks collects that route.
Registration does not execute `OrderGetUseCase.Execute`.

At request time the registered **handler method is the business entrypoint**.
The process/server/router gets the request to that method; it owns no order policy.

```text
GET /api/v1/orders/42
  |
  v
HTTP server -> middleware -> registered router
  |
  v
http/chi/handler/order_handler.go: HandleGetOrder       HTTP ENTRYPOINT
  | r.Context() + trusted middleware -> actor 7
  | parses path "42" as uint64
  | constructs OrderGetInput{ID: 42, ActorID: 7}
  v
usecase.OrderGetUseCase.Execute                        SAME APPLICATION OPERATION
  | validates Input; repository loads OrderModel; access validator accepts owner
  | creates OrderGetOutput{ID: 42, Status: "pending"}
  v
Output/error returns directly to the handler
  |
  v
handler maps Output -> http/dto.OrderGetResponse
  | response.JSON(..., 200, responseDTO, nil)
  v
HTTP 200, Content-Type: application/json
{"data":{"id":42,"status":"pending"}}
```

GET has no request body, so it does not invent a body DTO. The HTTP response DTO
is still required: it owns the wire representation independently of Output.
The exact operation and repository are the same ones used by CLI; HTTP does
not maintain a second copy of ownership/business policy.

## Complete handler

`internal/modules/order/http/chi/handler/order_handler.go`. Trusted middleware
supplies `ActorID`; IDs from URL/JSON are caller-controlled data. The constructor
receives `*usecase.OrderGetUseCase`, the Bricks renderer and logger.

```go
package handler

import (
	"context"
	"net/http"
	"strconv"

	"example.com/project/internal/modules/order/errs"
	"example.com/project/internal/modules/order/http/mapper"
	"example.com/project/internal/modules/order/usecase"
	"github.com/cristiano-pacheco/bricks/pkg/http/response"
	"github.com/cristiano-pacheco/bricks/pkg/logger"
	"github.com/go-chi/chi/v5"
)

type ActorID func(context.Context) (uint64, bool)

type OrderHandler struct {
	orderGet     *usecase.OrderGetUseCase
	actorID      ActorID
	errorHandler response.ErrorHandler
	logger       logger.Logger
}

func NewOrderHandler(
	orderGet *usecase.OrderGetUseCase,
	actorID ActorID, errorHandler response.ErrorHandler, log logger.Logger,
) *OrderHandler {
	return &OrderHandler{orderGet: orderGet, actorID: actorID, errorHandler: errorHandler, logger: log}
}

func (h *OrderHandler) HandleGetOrder(w http.ResponseWriter, r *http.Request) {
	actorID, authenticated := h.actorID(r.Context())
	if !authenticated || actorID == 0 {
		h.errorHandler.Error(w, errs.ErrUnauthenticated)
		return
	}
	id, err := strconv.ParseUint(chi.URLParam(r, "id"), 10, 64)
	if err != nil || id == 0 {
		h.errorHandler.Error(w, errs.ErrInvalidInput)
		return
	}
	output, err := h.orderGet.Execute(r.Context(), usecase.OrderGetInput{ID: id, ActorID: actorID})
	if err != nil {
		h.errorHandler.Error(w, err)
		return
	}
	if err := response.JSON(w, http.StatusOK, mapper.ToOrderGetResponse(output), nil); err != nil {
		h.logger.Error("write order response", logger.Error(err))
	}
}
```

[HTTP DTO](http-dto.md) owns `OrderGetResponse`, [Mapper](mapper.md) owns
`ToOrderGetResponse`, [Use case](usecase.md) owns Input/Output and policy, and
[Repository](repository.md) owns the GORM adapter. Only for an explicitly
requested decorator or when changing an already decorated operation, follow
[Usecase decorator](usecase-decorator.md) and adapt that consumer's signature to
the published decorated contract. A decorated application alone does not opt
this operation into decoration.

## Body-based operation: create

The complete [HTTP body example](http-body.md) implements this separate trace:

```text
POST /api/v1/orders + JSON {"notes":"deliver in the morning"}
  -> registered HandleCreateOrder
  -> trusted middleware actor + Bricks bounded body decoder
  -> http/dto.OrderCreateRequest (wire fields only)
  -> OrderCreateInput{ActorID: trustedActor, Notes: request.Notes}
  -> concrete OrderCreateUseCase.Execute
  -> shared shape validation -> model.OrderModel -> port.OrderRepository.Create
  -> concrete repository persists -> model with generated ID
  -> OrderCreateOutput{ID: persistedID, Status: persistedStatus}
  -> http/dto.OrderCreateResponse
  -> HTTP 201 {"data":{"id":persistedID,"status":persistedStatus}}
```

The body DTO never becomes the operation Input by alias/embedding, and its JSON
cannot overwrite the trusted actor. [HTTP body](http-body.md) states the pinned
parser's actual guarantees. Register the creation handler and POST route when
exposing it; providing the application operation alone creates no HTTP endpoint.

## Success and rejection

| Situation | Execution stops at | Result |
| --- | --- | --- |
| Missing trusted identity | Handler before Execute | 401 through shared error renderer |
| Malformed/zero path ID | Handler before Execute | 400; no operation call |
| Malformed create body | Body decoder before Execute | Classified decode error; no operation call |
| Valid JSON, invalid operation fields | Use-case validation | Validation error rendered as 422 |
| Record absent | Repository, propagated directly through use case | Catalog code/status, normally 404 |
| Existing row owned by another actor | Use-case access validator | Catalog rejection; this example permits a distinct 403 |
| Unexpected storage failure | Adapter error propagated to shared renderer | Safe generic 500; no driver text on the wire |
| Success response write fails | Handler after headers may commit | Log terminal write failure; no second response or repeated Execute |

Preserve the project's disclosure policy when absence and forbidden outcomes
must be indistinguishable. [Error](error.md) owns catalog/translation semantics.

*Check:* registered handler is the entrypoint, HTTP-owned DTOs, caller context,
one public operation call, the shared business policy, exact envelope/status,
and no success rendering when Execute returns an error.
