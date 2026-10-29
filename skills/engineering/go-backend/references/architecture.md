# Architecture

Read when dependency/import direction, representation ownership or module public
boundaries are being designed/assessed. [Data flow](data-flow.md) owns runtime
execution, entrypoints and return paths; [Module](module.md) owns package selection.
A verified local edit does not automatically load either broader guide.

## Dependency contract

Transport imports public operation Input/Output and consumes the published generic
use-case interface. Raw use cases consume application interfaces and values;
Bricks provides shared shape validation. A repository implements its port and
receives the initialized concrete database wrapper. Fx imports constructors and
binds their concrete instances to interfaces at the owner composition root.

| Owner | Permitted dependency for this responsibility |
| --- | --- |
| cmd business entrypoint / HTTP handler | Public application operation and its own transport/mapping collaborators |
| Raw usecase | Owned application values, ports, GORM model values internally and shared input validator |
| port | Consumed contracts and their allowed owned value types |
| repository | Its port/model, shared database and persistence library |
| validator/service | Its consumed application contracts; an evidence validator uses read ports |
| mapper | Only representations its boundary may see; pure conversion |
| fx composition | Concrete constructors and the interfaces under which consumers resolve them |

A port is an interface declaration, not an extra runtime layer. `model` owns GORM
persistence data, `dto` shared application values, `enum` validated values and
`errs` failure classification. Public operation Input/Output expose no persistence
model, SDK payload, HTTP type or Cobra value. Wire DTOs remain transport-owned.
[Consistency](consistency.md) defines the explicit GORM transaction-port exception.

Cross-module business interactions consume the owner's public operation API,
keeping its repository/model/private implementation packages internal to that
module. Keep both import and runtime dependency graphs acyclic. A raw operation
never depends on its own decorated publication.

*Check:* each dependency serves the declared owner; public representations respect
boundaries; constructors stay concrete; cross-module calls use public operations.
