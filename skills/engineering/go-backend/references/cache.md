# Cache

Add caching only when the operation identifies cached state, its authority, and
failure policy. A derived order cache does not replace the database. Session or
coordination state may have a different authority contract; declare it explicitly.
Do not scaffold an empty cache or no-op binding just to make the module complete.

## Recipe: cache contract and adapter

1. Define a consumer-owned `<Name>Cache` interface using application values,
   never Redis/serialized types. Distinguish hit, miss, and failure explicitly.
2. The adapter owns namespaced keys, encoding/version, TTL, and Redis calls.
   Context is first. TTL belongs to its configured cache policy, not every
   application method signature. A miss is neither a zero-valued hit nor failure.
3. For derived state, fetch authority on miss according to the operation's
   fallback rule. Serialization or dependency failure follows the declared
   failure policy; never silently relabel it as a miss.
4. Invalidate/refresh only after the authoritative commit. Define bounded staleness
   and retry behavior; a failed cache write does not undo a database commit.
5. Use a stable prefix. Add bounded TTL jitter for large synchronized batches
   when it is a real requirement, not a mandatory extra dependency for every key.

## Example: typed cache port

`internal/modules/order/port/order_summary_cache.go`.

```go
package port

import (
	"context"

	"example.com/project/internal/modules/order/dto"
)

type OrderSummaryCache interface {
	Get(ctx context.Context, id uint64) (dto.OrderSummary, bool, error)
	Set(ctx context.Context, value dto.OrderSummary) error
	Delete(ctx context.Context, id uint64) error
}
```

`internal/modules/order/cache/order_summary_cache.go`. Use the project's pinned
Redis client and transport lifecycle; this example consumes the process-owned go-redis v9 universal interface.

```go
package cache

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"time"

	"example.com/project/internal/modules/order/dto"
	"example.com/project/internal/modules/order/port"
	"github.com/redis/go-redis/v9"
)

const orderSummaryTTL = 10 * time.Minute

type orderSummaryValue struct {
	ID     uint64 `json:"id"`
	Status string `json:"status"`
}

type OrderSummaryCache struct{ client redis.UniversalClient }

var _ port.OrderSummaryCache = (*OrderSummaryCache)(nil)

func NewOrderSummaryCache(client redis.UniversalClient) *OrderSummaryCache {
	return &OrderSummaryCache{client: client}
}

func (c *OrderSummaryCache) Get(ctx context.Context, id uint64) (dto.OrderSummary, bool, error) {
	data, err := c.client.Get(ctx, c.key(id)).Bytes()
	if errors.Is(err, redis.Nil) {
		return dto.OrderSummary{}, false, nil
	}
	if err != nil {
		return dto.OrderSummary{}, false, err
	}
	var value orderSummaryValue
	if err := json.Unmarshal(data, &value); err != nil {
		return dto.OrderSummary{}, false, fmt.Errorf("decode order cache: %w", err)
	}
	if value.ID != id || value.Status == "" {
		return dto.OrderSummary{}, false, fmt.Errorf("invalid order cache value")
	}
	return dto.OrderSummary{ID: value.ID, Status: value.Status}, true, nil
}

func (c *OrderSummaryCache) Set(ctx context.Context, value dto.OrderSummary) error {
	data, err := json.Marshal(orderSummaryValue{ID: value.ID, Status: value.Status})
	if err != nil {
		return fmt.Errorf("encode order cache: %w", err)
	}
	return c.client.Set(ctx, c.key(value.ID), data, orderSummaryTTL).Err()
}

func (c *OrderSummaryCache) Delete(ctx context.Context, id uint64) error {
	return c.client.Del(ctx, c.key(id)).Err()
}

func (c *OrderSummaryCache) key(id uint64) string {
	return fmt.Sprintf("order:summary:v1:%d", id)
}
```

*Check:* real controlled Redis proof for hit/miss/failure, key namespace,
serialization compatibility, delete, TTL, and cancellation. Application proof
covers declared fallback and post-commit invalidation; a cache mock alone does
not prove Redis expiration or delivery semantics.

## Connection setup

The adapter borrows the process-owned Redis connection. Follow [Redis](redis.md)
only when client exposure or connection ownership changes. For Bricks APIs,
topology, namespacing, credentials, or instrumentation, use the conditional
[Bricks handoff](bricks.md). The cache guide owns policy, not connection mechanics.

## Publish the cache port

`internal/modules/order/cache_fx.go`. Include this option in the owning module
only when an operation consumes the cache port. The process provides the Redis
universal interface through its shared connection composition; the adapter opens no
new connection and its constructor still returns the concrete cache instance.

```go
package order

import (
	"example.com/project/internal/modules/order/cache"
	"example.com/project/internal/modules/order/port"
	"go.uber.org/fx"
)

var CacheModule = fx.Module("order-cache", fx.Provide(
	fx.Annotate(cache.NewOrderSummaryCache, fx.As(new(port.OrderSummaryCache))),
))
```
