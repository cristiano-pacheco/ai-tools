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

## Framework parsing and metadata

For Bricks query parsing, normalization, offset helpers, and response metadata,
follow [Bricks handoff](bricks.md) to `recipes/pagination-response.md`. Keep the
application's published query and response names. A helper's default metadata
does not authorize changing `page_size` or `total` in an existing API.

Reject malformed supplied values before normalization. Bound page size and
offset arithmetic even if the selected helper does not. Pass application
primitives to the use case and storage-owned criteria to the repository.
