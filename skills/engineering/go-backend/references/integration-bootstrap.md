# Integration bootstrap

Read when changing a controlled storage fixture, migration stack, or composed application test. A pure mapper test does not start containers.

## 1. Select the required stack

| Guarantee | Fixture |
| --- | --- |
| Persistence, constraint, transaction | Real database, production SQL, fresh state |
| Cache TTL, hit, miss, invalidation | Real isolated Redis and owned key space |
| Database plus cache | Both resources with separate cleanup ownership |
| Runtime publication | Production module and the intended public operation |
| HTTP transport | API end-to-end application through a listening server under [Test policy](test-policy.md) |
| Uncontrolled third-party effect | Replace only its allowed application port |

Usecase and service operations remain the integration targets. Real repositories and caches are collaborators, not separate default suites.

## 2. Set up framework resources

For Bricks, follow [Bricks handoff](bricks.md) to the selected testkit guide. Use its actual startup, client, migration, reset, and cleanup APIs. Register cleanup before startup can fail. Do not replace a failed fixture with a passing mock or retry a once-guarded instance as if it were fresh.

Use scoped cleanup. Never remove containers or reset databases belonging to another test process. Shared destructive resets require serial execution. A fresh fixture per test is the simpler isolation choice when cost permits it.

## 3. Apply the complete schema

Reuse production migrations, including foreign-key owners. Choose one migration path rather than applying two partial schemas. For a multi-module embedded runner, collect the actual production contributions and enforce global unique versions. Do not create missing tables manually to make a partial migration set pass.

Bricks' `references/itestkit/embedded-migrations.md` covers its PostgreSQL bridge when that setup is needed. A fixture that bypasses the production database constructor does not prove that constructor's configuration or lifecycle.

## 4. Resolve the claimed consumer

For direct-operation proof, construct the real concrete use case and its adapters. For graph publication, use its actual production module. Supply only the settings and resources reached by that consumer. For selected decoration, resolve the public decorated operation; raw execution does not exercise its effects.

An unused provider, a resolved route group, and successful graph validation do not prove HTTP readiness. Use the API end-to-end boundary for transport claims. Verify the installed server's listener behavior when startup readiness matters.

Done when the required stack starts, production SQL applies, isolated operations execute, and owned resources stop. Record missing infrastructure as unrun proof.
