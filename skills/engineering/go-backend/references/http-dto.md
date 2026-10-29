# HTTP DTO

Create `http/dto/<resource>_dto.go`, request types before response types. Name
wire fields exactly with JSON tags. Keep GORM tags, models, SDK types, business
methods, and application policy out. An HTTP DTO never aliases/embeds an
operation input/output merely because the fields match.

## Recipe: request and response

1. Define the published wire fields, required/optional/null meaning, numeric
   ranges/units, and compatibility requirements. Bodyless operations do not need
   fabricated empty body types; any actual payload has HTTP-owned representation.
2. Decode through the established bounded helper and map to the use-case input.
   Path/query/header syntax belongs to this boundary; business validation still
   runs for the full application input through every entry point.
3. Use pointer/optional wrappers only for promised absence semantics. A plain
   `*T` distinguishes value versus absent/null combined; it does not distinguish
   omitted from explicit JSON null by itself. Use an explicit presence wrapper
   when PATCH semantics need all three states.
4. Map output to a response DTO, including declared collection metadata. Preserve
   empty array/null conventions, dates, and enum wire literals.

## Example: response

`internal/modules/order/http/dto/order_dto.go`.

```go
package dto

type OrderGetResponse struct {
	ID     uint64 `json:"id"`
	Status string `json:"status"`
}
```

## Example: create body

`internal/modules/order/http/dto/order_create_dto.go`. Owner identity is resolved
from trusted authentication rather than this request body.

```go
package dto

type OrderCreateRequest struct {
	Notes *string `json:"notes"`
}
type OrderCreateResponse struct {
	ID     uint64 `json:"id"`
	Status string `json:"status"`
}
```

*Check:* exact wire names, ownership separation, explicit omission/null/zero
meaning, bounded decoding, compatible representation changes, and response proof.
