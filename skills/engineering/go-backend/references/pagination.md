# Pagination and filtering

Read only for a collection contract. Define accepted query names/types/defaults,
maximum size, omission versus empty-filter semantics, and fixed filter/sort
allowlists. Reject malformed syntax at HTTP; preserve application limits through
other transports. Arbitrary query keys/order expressions never become SQL.

The use case has its own list input/output. HTTP parses values into that input;
the use case maps to repository primitives or a model-owned criterion. The
repository receives neither `url.Values`, HTTP page DTO, nor the application input.

## Recipe: stable pages

1. Apply identical filters to total and page. Count before limit/offset and use
   deterministic ordering with a unique tie-breaker. [Repository query](repository-query.md)
   owns the storage mechanics when those change.
2. Define offset/page normalization and overflow bounds. With cursor pagination,
   bind the cursor to order/filter semantics and preserve stable key comparisons.
3. Return promised metadata and an explicitly empty item collection. A truncated
   page cannot establish total; concurrent writes may require snapshot semantics
   when page/total consistency is a public guarantee.
4. Map enum/date filters through checked conversion. Test both ends of limits,
   empty results, ties, and changed filters across pages.

## Example: collection wire response

`internal/modules/order/http/dto/order_list_dto.go`.

```go
package dto

type OrderListResponse struct {
	Items    []OrderGetResponse `json:"items"`
	Page     int                `json:"page"`
	PageSize int                `json:"page_size"`
	Total    int64              `json:"total"`
}
```

*Check:* explicit accepted values and caps; no SQL-shaped caller input;
consistent filters/count; stable order; documented metadata and empty-list shape.

## Bricks paginator

Use `pkg/paginator.ParseQueryParams`, `NormalizeParams`, `Params.Offset/Limit`
and `Metadata` rather than another parser. Its default wire names are `page` and
`per_page`; preserve an established API's different names explicitly. Parsing
rejects nonpositive provided values but does not cap page size or prevent offset
integer overflow. Normalize and bound those values before repository arithmetic.
Never let normalization silently turn malformed supplied values into defaults.

`internal/modules/order/http/mapper/order_page_mapper.go`. This boundary returns
application primitives; repository criteria remain storage-owned. The page cap
below is an example policy and bounds offset arithmetic on supported Go targets.

```go
package mapper

import (
	"fmt"
	"net/url"

	"example.com/project/internal/modules/order/errs"
	"github.com/cristiano-pacheco/bricks/pkg/paginator"
)

const maxOrderPage = 1_000_000
const maxOrderPerPage = 100

func ToOrderPage(query url.Values) (int, int, error) {
	parsed, err := paginator.ParseQueryParams(query, 1, 20)
	if err != nil {
		return 0, 0, fmt.Errorf("%w: %w", errs.ErrInvalidInput, err)
	}
	if parsed.Page > maxOrderPage {
		return 0, 0, errs.ErrInvalidInput
	}
	normalized := paginator.NormalizeParams(parsed.Page, parsed.PerPage, 1, 20, maxOrderPerPage)
	return normalized.Page, normalized.PerPage, nil
}
```

Map stable totals with `paginator.TotalPages(total, perPage)`. For a new collection
DTO, use `paginator.Metadata` only if that is the chosen public wire contract;
its fields are `total_count`, `page`, `per_page`, `total_pages`. Do not silently
replace the existing `page_size`/`total` example contract with those names.
