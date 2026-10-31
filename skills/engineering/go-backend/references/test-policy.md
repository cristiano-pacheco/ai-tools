# Test policy

Apply these defaults when planning, generating, or changing tests, including for
implementation, bug fixes, refactoring, and coverage requests. Explicit user
requests and project-mandated test contracts override the defaults; a generic
request for integration tests or coverage does not override them.

| Target | Default |
| --- | --- |
| Usecases and services | Integration tests through their public operations, including services whose logic is pure. |
| Dependency-free behavior outside those components, such as pure mapper or enum functions | Unit tests without mocks or test doubles. |
| Repositories, models, caches | No direct unit or integration tests. Exercise their behavior through a usecase or service integration test when relevant. |
| Cobra commands | No direct tests. |
| HTTP handlers, routers, middleware and other transport components | No direct unit or integration tests. |
| HTTP and gRPC APIs | End-to-end tests through the actual transport boundary when transport behavior needs coverage. |
| Other transports | No end-to-end tests by default. |

Choose the component under test, not every file or dependency exercised along the
way. For example, a usecase integration test may use a real repository and cache
without creating separate repository or cache suites. Do not use mocks to turn a
usecase or service into a unit test by default. If a requested guarantee has no
applicable default test boundary, report the verification gap rather than adding
an excluded test or claiming it was proven. An explicit request for an excluded
boundary permits that specific test; do not expand the exception to other targets.

## HTTP boundary decision

For business behavior exposed over HTTP, call the usecase or service public
operation directly in its integration suite. Adding an endpoint, changing a
handler, fixing a bug, or requesting integration coverage does not authorize a
handler suite. A real database, Fx graph, registered router, or placement under
`test/integration/` does not change the component under test.

For HTTP transport coverage, use an API end-to-end suite: start the application
with its production composition, routes, middleware and required real controlled
adapters; send requests with an HTTP client through a listening server. An
isolated handler or router wrapped in `httptest.NewServer` is still a component
test. Calling a handler method or `Router().ServeHTTP` with a recorder is not
API end-to-end proof. Reuse the project's end-to-end harness when available;
otherwise build that boundary or report the missing verification.

Before adding a test, identify its target, invocation boundary and applicable
policy row. Apply the same check to the final diff. Reject direct handler,
router, middleware, parser or renderer unit/integration suites unless the user
explicitly requested that target or a project contract mandates it. Move business
assertions to usecase/service integration coverage and transport assertions to
API end-to-end coverage. Renaming or relocating a component test does not make
it compliant.
