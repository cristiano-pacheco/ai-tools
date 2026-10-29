# Application DTO

## Choose the owner

One operation's input/output belongs beside that use case; each wrapper is a
named struct with explicit fields, even when empty. Shared application values
belong in module `dto` only when multiple application collaborators need the
same canonical shape. HTTP DTOs live in `http/dto`; GORM records/views live in
`model`. Equal fields do not merge these ownership boundaries.

A new operation does not alias, embed, or define its input/output from another
operation's wrapper. Reuse a canonical value through a named field. Shared
application DTOs carry no JSON, database, provider, or transport tags. Provider
and cache ports may use them; repository ports continue to use model values.

## Recipe: introduce a shared shape

1. Name the consumers and the compatibility/validation meaning they
   share. Keep an operation-only nested value local to its wrapper file.
2. Define explicit fields in `dto/<name>_dto.go` with units and optionality from
   the application contract. Extract shared representation, not shared workflow.
3. Map each owner's representation explicitly. A caller never receives a model
   disguised as a DTO through aliasing or embedding.
4. Check all consumers before changing a canonical value; an operation-specific
   field remains on that operation unless every consumer shares its meaning.

## Example: shared application value

`internal/modules/order/dto/order_summary_dto.go`.

```go
package dto

type OrderSummary struct {
	ID     uint64
	Status string
}
```

For a list operation, use its own `OrderListInput` and `OrderListOutput`, with
`Items []dto.OrderSummary` and promised metadata as explicit output fields.
Filters and limits are application values; GORM clauses and HTTP query names
belong to their adapters. The same shared value may be cached through a cache
port without turning that serialized payload into the public operation wrapper.

*Check:* each DTO has a named owner and real consumers; each operation retains
its input/output; model/provider/wire types remain behind their boundaries.
