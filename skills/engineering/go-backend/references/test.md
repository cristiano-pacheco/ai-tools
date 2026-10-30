# Test routing

First read [Test policy](test-policy.md) whenever planning, generating, or changing
tests. Apply its target and exception rules before selecting a recipe below; select
proof by observable contract, not every dependency constructed by the suite.

| Guarantee | Read |
| --- | --- |
| Dependency-free behavior eligible for unit tests | [Unit test](unit-test.md) |
| Usecase or service public operation and its effects | [Integration test](integration-test.md) |
| HTTP or gRPC API transport behavior | End-to-end test through the actual API boundary |
| Explicitly requested Cobra command test | [Command test](command-test.md) |
| Explicitly required Fx dependency reachability/binding proof | [Fx](fx.md); distinguish graph validation from runtime proof |

Select the asserted behavior's component recipe as well as this boundary. A test-only
request does not authorize production behavior changes; report a discovered
production defect before broadening scope. A resource-text-only edit does not
necessarily select a Go test guide.

Use real controlled infrastructure for database/locking/Redis/protocol guarantees.
An uncontrolled external provider may be replaced at its port only when allowed.
Assert output, persisted state, effects and negative state on failure, stable
error identity, and caller cancellation where relevant. Keep waits bounded and
fixtures isolated; synchronize on observable conditions instead of sleeps.

Run focused proof while editing, then required project checks once for the final
change. Report skipped/unavailable checks explicitly. A build, fake, or graph
validation cannot stand in for an unexecuted runtime/storage guarantee.
