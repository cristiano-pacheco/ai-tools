# Port

## Define the consumed contract

Create `internal/modules/<module>/port/<capability>_<role>.go` in the consuming
module. `port` contains interface declarations only. Application values live in
`dto`, persistence values/views/criteria in `model`, operation input/output beside
its use case, and implementations beside their technical mechanism.

| Application need | Interface / implementation owner |
| --- | --- |
| Persist owned data | `<Entity>Repository` / `repository` |
| Reusable acceptance rule | `<Name>Validator` / `validator` |
| Other reusable I/O capability | `<Name>Service` / `service` |
| Remote service protocol | `<Name>Client` / `client` |
| Third-party capability | `<Name>Provider` / `provider` |
| Cache mechanics | `<Name>Cache` / `cache` |
| Explicit application transaction | `TransactionProvider` / `repository` |

Declare only consumed methods, with context first for I/O. Document absence,
ordering, atomicity, and retry/delivery guarantees when signatures cannot express
them. Do not let configuration, SDK types, HTTP requests, Redis clients, or
concrete implementations leak through signatures.

A repository port exchanges model values and primitive/persistence criteria;
other outbound ports use module-owned application values. The explicit
transaction provider and `*TX` participant contract are the only `*gorm.DB`
exception. HTTP/application DTOs and pointers to models are not persistence
port values. Pure mapper functions need no interface; named validators retain
their port even when stateless.

## Implement and publish

The implementation asserts its port below its type, and its constructor returns
the concrete instance. The use case receives the interface. [Fx](fx.md) adapts
that constructor result with `fx.As`, not a second interface-returning factory.
See [Repository](repository.md#example-repository-port) for a complete persistence
example; select [Client](client.md), [Provider](provider.md), [Cache](cache.md),
or [Service](service.md) only for the matching boundary being changed.

*Check:* consumer ownership, method necessity, representation ownership, absence
semantics, context, constructor/assertion agreement, and actual Fx resolution.
