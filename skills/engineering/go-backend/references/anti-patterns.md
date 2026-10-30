# Go anti-patterns

Read on every invocation of this skill, including implementation, refactoring,
investigation and review. Apply each relevant entry to the code in scope.
Implementation fixes violations introduced by the change before completion;
read-only work reports violations without editing. Do not expand a local task
into a repository-wide migration of pre-existing code.

## AP-001 — Catch-all packages

**Pattern:** Creating or using application packages named `helper`, `helpers`,
`util`, `utils`, or equivalent responsibility-free buckets such as `common` or
`misc`. These package names are prohibited, including for a single function;
renaming a miscellaneous bucket does not give it a coherent responsibility.

**Why:** The name says how code is reused, not what it owns. Unrelated behavior
accumulates, callers acquire accidental dependencies, and package boundaries
stop expressing the architecture.

**Use instead:** Classify the behavior before choosing its owner:

- Operation-local orchestration stays in its use case.
- Component-internal logic is an unexported receiver method on its owning
  constructed component, following the skill's helper convention.
- Representation conversion belongs in the boundary-owned `mapper`.
- Extracted acceptance/rejection rules belong in `validator`.
- Persistence, protocol and SDK work belongs in `repository`, `client` or `provider`.
- Other reusable capabilities get a focused component named for their actual
  responsibility, not for being shared or convenient.

A single caller or stateless function does not justify a catch-all package.
Reuse alone does not justify creating a service, interface or constructor.
`internal/shared/` may remain a structural parent for focused infrastructure
packages such as `internal/shared/database`; it is not a miscellaneous Go package.

**Check:** Inspect package declarations, new directories and imports. Introduce
neither a prohibited package nor a new use of an existing catch-all package.
When changing code that already uses one, identify the proper owner and remove
or replace the in-scope usage where the task permits. Report remaining legacy
violations and any scope blocker instead of silently adopting the pattern.

## Maintaining this reference

Add new anti-patterns as separate entries with a stable `AP-NNN` identifier,
a concrete **Pattern**, its **Why**, the positive **Use instead** alternative,
and an observable **Check**. Keep each rule authoritative here and link to
component recipes rather than copying their implementation details. Add a
matching acceptance case in [Routing cases](../test/routing-case.md). Existing
entries apply automatically through the mandatory read in the skill entrypoint.
