# Usecase decorator test

Read for a selected decorated operation when publication, flags, or chain effects change. Apply [Test policy](test-policy.md) first. Reuse the operation's [integration fixture](integration-test.md) rather than starting another container stack.

1. Use the production owner module and its publication provider. Resolve the selected public operation, not a test-only call to the wrapper factory.
2. Supply the real controlled adapters and configuration needed by that consumer. Keep suites sequential when they change process environment or share mutable infrastructure.
3. Invoke the public operation. Assert its output, persisted effects, and negative state on rejection. A wrapper must not duplicate execution or weaken business policy.
4. Assert exactly one observation for each selected log, metric, or tracing effect. Do not assert timing values or private wrapper type names. A recording metrics dependency proves calls to that dependency, not Prometheus export.
5. Test the changed enabled and disabled profiles. When the framework promises raw-instance identity for a disabled chain, check it. For translation, distinguish raw identity from the public code and status contract.
6. For cancellation, use a cancelled or deadline context through real adapters. For tracing, verify the promised parent/child relationship. Neither context pointer equality nor an initialized exporter establishes those guarantees.

For Bricks configuration, factory dependencies, and effect-specific checks, follow [Bricks handoff](bricks.md) to `references/ucdecorator/verification.md`. Load only the integration guide needed for the claimed effect.

Done when production public keys resolve and the changed effects occur once without changing the operation's durable guarantees. Static graph validation is not runtime proof.
