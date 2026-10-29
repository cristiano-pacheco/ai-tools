# Mapper

## Recipe: convert at a representation boundary

1. Choose the owner before the helper: HTTP mapping belongs to its HTTP adapter;
   application/model conversion belongs to the module; CLI output conversion
   belongs to the command boundary. Keep imports acyclic.
2. Keep a trivial field copy inline. Extract reused, nested, parsed, or complex
   conversion as a pure function in `mapper`. Name exported functions `To<X>`
   for the destination. Collection conversion calls the item conversion.
3. Pass source values explicitly. Return one destination, plus `error` only for
   fallible conversion. Preserve units, null/zero distinctions, enums, and
   collection semantics. Respect the project's private-function convention.
4. Load additional data before mapping. A mapper owns no struct, interface,
   constructor, context, I/O, validation policy, logging, or runtime registration.

*Check:* all fields and semantic changes are accounted for; the function sees
only its owned representations; no model reaches the HTTP response or use-case
public contract.

## Example: HTTP response mapping

`internal/modules/order/http/mapper/order_mapper.go`. This mapper imports only
HTTP DTOs and public application contracts, never the GORM model.

```go
package mapper

import (
	httpdto "example.com/project/internal/modules/order/http/dto"
	"example.com/project/internal/modules/order/usecase"
)

func ToOrderGetResponse(output usecase.OrderGetOutput) httpdto.OrderGetResponse {
	return httpdto.OrderGetResponse{ID: output.ID, Status: output.Status}
}
```

## Recipe: collection and nested conversion

Map one item with `To<X>`, then have collection conversion call that function.
Define nil versus empty collection behavior from the wire contract; an allocated
empty slice encodes as `[]`, while a nil slice commonly encodes as `null`.
Nested assembly belongs to conversion even with one caller or a private receiver.
Split any repository/provider loading from the conversion before extraction.

`internal/modules/order/http/mapper/order_collection_mapper.go`.

```go
package mapper

import (
	httpdto "example.com/project/internal/modules/order/http/dto"
	"example.com/project/internal/modules/order/usecase"
)

func ToOrderGetResponseList(outputs []usecase.OrderGetOutput) []httpdto.OrderGetResponse {
	result := make([]httpdto.OrderGetResponse, len(outputs))
	for i, output := range outputs {
		result[i] = ToOrderGetResponse(output)
	}
	return result
}
```

## Recipe: fallible conversion

Return an error only when conversion can fail: parsing, overflow, incompatible
units, or unsupported enum representation. Preserve the parsing cause and the
stable application classification. Validation/authorization policy remains with
its owner; a mapper does not decide whether an actor may choose a valid date.

`internal/modules/order/mapper/delivery_date_mapper.go`.

```go
package mapper

import (
	"fmt"
	"time"

	"example.com/project/internal/modules/order/errs"
)

func ToDeliveryDate(value string) (time.Time, error) {
	date, err := time.Parse("2006-01-02", value)
	if err != nil {
		return time.Time{}, fmt.Errorf("%w: %w", errs.ErrInvalidDate, err)
	}
	return date, nil
}
```

Test omitted/null/zero semantics, empty collections, nested field coverage,
timezone/units, and rejected parses at the chosen boundary. Ordinary field copies
return no synthetic error and need no runtime binding, interface, or constructor.
