# Redis connection

Read when creating/changing the shared Redis client, config projection,
client exposure or lifecycle. Cache payload/key policy stays in [Cache](cache.md).

## Conditional Redis graph

`internal/shared/cache/fx.go`. Add `RedisModule` to the process only when consumed.
The plain-config projection is required by the actual Bricks v0.1.21 constructor;
its built-in module provides only the typed config wrapper.

```go
package cache

import (
	bricksconfig "github.com/cristiano-pacheco/bricks/pkg/config"
	bricksredis "github.com/cristiano-pacheco/bricks/pkg/redis"
	"go.uber.org/fx"
)

var RedisModule = fx.Module("shared-redis",
	bricksredis.Module,
	fx.Provide(func(loaded bricksconfig.Config[bricksredis.Config]) bricksredis.Config { return loaded.Get() }),
)
```

Add `app.redis` with `url`, `type: single_node` and actual pool/namespace settings.
`redis.Module` publishes the universal interface, not `*redis.Client` or the Bricks
wrapper. `ClientModule` is the alternative when that concrete wrapper is needed.
[Cache](cache.md) owns key/TTL/serialization and [Integration bootstrap](integration-bootstrap.md)
owns the real controlled stack used to prove it.


*Check:* constructor dependencies, one typed/plain config projection,
matching universal-versus-wrapper exposure, startup/closure and real controlled
Redis evidence for changed connection guarantees.
