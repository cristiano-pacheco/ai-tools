# Redis connection

Read when changing a shared Redis connection or its lifecycle. [Cache](cache.md) owns cache keys, payloads, TTL, authority, and invalidation.

1. Identify the required topology and the actual consumed client type. Preserve the project's accepted connection profile.
2. For Bricks constructors, YAML, config projection, or client exposure, follow [Bricks handoff](bricks.md). Select only the matching topology and load the client-behavior guide only when its contract matters.
3. Register the connection once at its process owner. Consumers borrow it. Do not introduce a second client merely to adapt its public type.
4. Prove changed startup, connectivity, and closure with controlled Redis. Cache behavior needs separate assertions through the public usecase or service boundary under [Test policy](test-policy.md).

Done when consumers resolve the intended client and its owner starts and closes it. Registering a provider alone does not establish a usable connection.
