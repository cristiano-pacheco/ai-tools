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
