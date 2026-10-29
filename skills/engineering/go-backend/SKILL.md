---
name: go-backend
description: Develop, fix, refactor, test, investigate, or review Go backends. Routes module design, REST/Cobra operations, GORM persistence, and Fx composition to focused playbooks and component recipes.
---

# Go backend

## Principles

- **Ownership.** Transport decodes and renders. Use cases decide and orchestrate.
  Adapters perform I/O, validators accept or reject, and mappers convert. Classify helpers by
  their bodies as well as public methods.
- **Contracts.** Read project instructions, ADRs, callers, go.mod and checks.
  User choices and project contracts override defaults. Use singular package
  names, GORM, Chi, Cobra, Fx and Bricks for new projects. Application struct
  constructors return concrete instances and may also return an error. Fx binds ports.
- **Scope.** A module owns a business capability. Create components its behavior
  needs and preserve accepted structure outside scope. Ask for missing business
  decisions; resolve technical facts from the repository.
- **Boundaries.** One business entrypoint invokes one public operation. Its
  Input/Output contain no HTTP, Cobra, storage or vendor types.
- **Proof.** Test the claimed behavior at its execution boundary. Compilation,
  mocks and unavailable tools do not prove untested runtime behavior.

## Choose a playbook

Select by requested outcome and read the playbook in full:

| Outcome | Playbook |
| --- | --- |
| New/changed behavior, API, config or runtime | [Implementation](workflows/implementation.md) |
| Reproduce and correct a defect | [Bug fix](workflows/bug-fix.md) |
| Change structure while preserving behavior | [Refactoring](workflows/refactoring.md) |
| Add coverage without changing production behavior | [Test](workflows/test.md) |
| Explain or diagnose without editing | [Investigation](workflows/investigation.md) |
| Assess and report findings | [Review](workflows/review.md) |

For multi-step work, copy its numbered steps into the task list before adding
specific tasks. Keep nonapplicable steps with reasons. Required proof remains
required. A fix with tests stays Bug fix; follow-ups retain the playbook until
the requested outcome changes. Performance work needs comparable before/after
measurements. Investigation and review remain read-only unless changes are requested.

## Select references

Use [Routing](references/routing.md). Read a component guide before creating,
changing or assessing its contract. For unchanged collaborators, inspect the
needed signature/callers and stop once their relevant contract is verified.
Links are conditional; do not recursively load every linked file. Re-select
when evidence changes ownership, scope or an unverified contract.

- [Module](references/module.md) defines package ownership and module boundaries.
- [Data flow](references/data-flow.md) defines entrypoints, collaborator sequence
  and Input/Output return paths; select its CLI or HTTP branch.
- [Bricks](references/bricks.md) resolves package/API/version choices;
  [Bootstrap](references/bootstrap.md) selects process stack recipes.
- [Usecase decorator](references/usecase-decorator.md) defines public publication
  and decoration, the default for new Bricks applications.

Code examples stay inline in the selected Markdown reference. Adapt module
imports and project contracts; an example does not require unrelated dependencies.

## Completion

Check ownership, representations, registration and playbook acceptance criteria
against the final diff. Run required project checks and report executed evidence,
failed/unrun checks and blockers. Required checks must pass before completion.
Skill edits also exercise [Routing cases](test/routing-case.md).
