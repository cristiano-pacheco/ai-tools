# HTTP body

Read when a handler accepts JSON. [Request](request.md) owns decoding, limits,
null handling and parser code/status contracts. [Response](response.md) owns
success/error rendering. Keep application validation in the use case.

## Example: create boundary

`internal/modules/order/http/chi/handler/order_create_handler.go`. This follows
the framework parser's documented behavior above, with a 64 KiB read bound.
Provide its constructor and decorated operation in the owner's Fx graph and
attach `HandleCreateOrder` to the resource's POST route when creation is exposed.

```go
package handler

import (
	"net/http"

	"example.com/project/internal/modules/order/errs"
	httpdto "example.com/project/internal/modules/order/http/dto"
	"example.com/project/internal/modules/order/usecase"
	"github.com/cristiano-pacheco/bricks/pkg/http/request"
	"github.com/cristiano-pacheco/bricks/pkg/http/response"
	"github.com/cristiano-pacheco/bricks/pkg/logger"
	"github.com/cristiano-pacheco/bricks/pkg/ucdecorator"
)

const maxOrderCreateBodyBytes = 64 << 10

type OrderCreateHandler struct {
	operation    ucdecorator.UseCase[usecase.OrderCreateInput, usecase.OrderCreateOutput]
	actorID      ActorID
	errorHandler response.ErrorHandler
	logger       logger.Logger
}

func NewOrderCreateHandler(
	operation ucdecorator.UseCase[usecase.OrderCreateInput, usecase.OrderCreateOutput],
	actorID ActorID, errorHandler response.ErrorHandler, log logger.Logger,
) *OrderCreateHandler {
	return &OrderCreateHandler{operation: operation, actorID: actorID, errorHandler: errorHandler, logger: log}
}

func (h *OrderCreateHandler) HandleCreateOrder(w http.ResponseWriter, r *http.Request) {
	actorID, authenticated := h.actorID(r.Context())
	if !authenticated || actorID == 0 {
		h.errorHandler.Error(w, errs.ErrUnauthenticated)
		return
	}
	var body *httpdto.OrderCreateRequest
	if err := request.ReadJSONWithMaxSize(w, r, &body, maxOrderCreateBodyBytes); err != nil {
		h.errorHandler.Error(w, err)
		return
	}
	if body == nil {
		h.errorHandler.Error(w, errs.ErrInvalidInput)
		return
	}
	output, err := h.operation.Execute(r.Context(), usecase.OrderCreateInput{ActorID: actorID, Notes: body.Notes})
	if err != nil {
		h.errorHandler.Error(w, err)
		return
	}
	result := httpdto.OrderCreateResponse{ID: output.ID, Status: output.Status}
	if err := response.JSON(w, http.StatusCreated, result, nil); err != nil {
		h.logger.Error("write created order response", logger.Error(err))
	}
}
```

*Check:* decode into the HTTP DTO, reject a null object, keep trusted identity
separate, preserve parser errors and invoke the operation only after decoding.
