# Bootstrap routing

Read when deciding/changing the process stack. Select only the affected branch;
an existing verified process does not reload these guides for a local operation.
Cobra owns executable boundaries, Fx owns composition/lifecycle, and Bricks owns
the reusable platform mechanisms.

| Process responsibility | Read | Stop condition |
| --- | --- | --- |
| New server graph, root command, complete base YAML | [Server](server.md) | Shared infrastructure once, business modules once, HTTP contribution reachable; real readiness separately proved. |
| Migration command and collected SQL runner | [Migration command](migration-command.md) | Same owned module assets, correct connection format, errors returned without starting HTTP. |
| Redis construction, config projection, interface/wrapper exposure | [Redis](redis.md) | The consumed client resolves and its owned connection starts/closes; cache policy remains separate. |

Use [Bricks](bricks.md) only when package/API/version selection is unresolved.
Use [Configuration](configuration.md) for loader/overlay/environment contracts,
[Fx](fx.md) for provider/binding changes and [Runtime](runtime.md) for changed
resource ownership. These links are conditional, not a requirement to load every
platform guide. A calculation gets no database and a server gets no Redis solely
because the framework provides them.

New HTTP/public-operation stacks follow the JBN approach: concrete raw
constructors, public decorated publication, existing framework route/error
contracts, and module-owned SQL/locale contributions. Preserve an established
project's accepted infrastructure/profile outside the requested scope.
