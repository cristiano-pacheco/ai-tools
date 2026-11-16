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

## AP-002 — Single-line function bodies

**Pattern:** Putting a function's opening brace, statements, and closing brace
on one line, even for trivial constructors, getters, test helpers or callbacks.

```go
// Anti-pattern
func NewCodeGeneratorService() *CodeGeneratorService { return &CodeGeneratorService{} }
```

**Why:** Compact bodies hide the executable step and make examples inconsistent
with the required multiline style. A trivial implementation is not an exception;
`gofmt` alone does not enforce this rule.

**Use instead:** Put the body on indented lines and the closing brace on its own
line. Apply this to functions, methods and anonymous functions, including tests.

```go
func NewCodeGeneratorService() *CodeGeneratorService {
	return &CodeGeneratorService{}
}
```

**Check:** Inspect every added/changed function body, including constructors,
methods and callbacks. Expand single-line bodies before completion; formatting
success alone is insufficient. Inline composite literals are not function bodies.

## AP-003 — Abbreviated dependency names

**Pattern:** Shortening injected collaborator fields or constructor parameters to
names such as `create`, `get`, or `errors`. Do not shorten existing descriptive
names.

```go
// Before
func NewLinkHandler(
	create *usecase.LinkCreateUseCase,
	get *usecase.LinkGetUseCase,
	errors response.ErrorHandler,
) *LinkHandler {
	return &LinkHandler{create: create, get: get, errors: errors}
}
```

**Why:** Short names obscure which component each dependency represents.

**Use instead:** Name fields and constructor parameters for the collaborator
and its role. Use the same names in assignments and calls.

```go
// After
type LinkHandler struct {
	linkCreateUseCase *usecase.LinkCreateUseCase
	linkGetUseCase    *usecase.LinkGetUseCase
	errorHandler      response.ErrorHandler
}

func NewLinkHandler(
	linkCreateUseCase *usecase.LinkCreateUseCase,
	linkGetUseCase *usecase.LinkGetUseCase,
	errorHandler response.ErrorHandler,
) *LinkHandler {
	return &LinkHandler{
		linkCreateUseCase: linkCreateUseCase,
		linkGetUseCase:    linkGetUseCase,
		errorHandler:      errorHandler,
	}
}
```

**Check:** Inspect added or changed dependency fields, constructor parameters,
assignments and uses. Preserve descriptive existing names and replace shortened
names in scope with names identifying the collaborator and its role.

## Maintaining this reference

Add new anti-patterns as separate entries with a stable `AP-NNN` identifier,
a concrete **Pattern**, its **Why**, the positive **Use instead** alternative,
and an observable **Check**. Keep each rule authoritative here and link to
component recipes rather than copying their implementation details. Add a
matching acceptance case in [Routing cases](../test/routing-case.md). Existing
entries apply automatically through the mandatory read in the skill entrypoint.
