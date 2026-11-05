# Usecase decorator

Read only when decoration is explicitly requested or when changing the publication or chain of an existing decorated operation. [Use case](usecase.md#execution-profile) defines direct concrete execution as the default. An installed factory or a decorated neighboring operation does not opt a new operation in.

## 1. Identify the selected operations

Keep each raw operation's concrete constructor and named Input/Output. List only the operations that need decoration and the effects each public call must have. Generic logging, metrics, tracing, and translation stay outside raw `Execute`. Validation, authorization, transaction scope, and durable success remain inside it.

## 2. Publish once at composition

Register each raw constructor once. Wrap each selected instance once at its module's publication provider. HTTP, Cobra, and cross-module callers consume the intended public contract. Do not wrap in a handler, command, another decorator, or `Execute`.

For Bricks factories, manual chains, generic publication, flags, names, and dependencies, follow [Bricks handoff](bricks.md) to the selected `ucdecorator` guide. Use its existing mechanisms rather than creating a second generic framework. Keep application constructors concrete in either execution profile.

## 3. Preserve dependency direction

A raw use case never injects its own decorated publication. Cross-module calls use the other module's public operation. Keep imports and the runtime graph acyclic. Distinct operations need distinct named input/output types when their generic specializations identify public keys. Type aliases do not create distinct types.

## 4. Verify the public path

Resolve and invoke the production public publication, not a test-only wrapper. Verify one raw execution and one observation per requested effect. Preserve caller cancellation and values. A child tracing context need not have the same pointer identity. Translation may change error identity, so assert the promised public contract as described in [Error](error.md).

Read [Usecase decorator test](usecase-decorator-test.md) for changed publication, flags, or effects. A local policy edit with verified unchanged wiring does not load decorator setup or tests.

Done when selected operations publish once, consumers resolve the intended instance, effects match the request, and unrelated direct or decorated operations keep their existing profiles.

## Direct profile

Provide `NewOrderGetUseCase` directly and inject `*usecase.OrderGetUseCase`. No decorator interface, factory, publication provider, or decorator configuration is needed solely because this guide exists.
