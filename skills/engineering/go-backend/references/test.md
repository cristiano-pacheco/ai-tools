# Test routing

Project-mandated boundaries/runners override defaults. Select proof by observable
contract, not library names or every dependency constructed by the suite.

| Guarantee | Read |
| --- | --- |
| Deterministic mapper, enum, validator, pure service, permitted isolated collaborator behavior | [Unit test](unit-test.md) |
| Application persistence/effects, repository, transaction, migrated schema, controlled cache/protocol, composed module | [Integration test](integration-test.md) |
| Cobra parsing, mapping, output, errors, process boundary | [Command test](command-test.md) |
| HTTP method/path, decode, middleware, render | REST's selected HTTP component and existing composed HTTP boundary |
| Fx dependency reachability/binding | [Fx](fx.md); add integration for constructor/resource/lifecycle success |

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
