---
name: go-usecase
description: Generate Go use cases in internal/modules/<module>/usecase/ with strict entity-first naming, validate-tagged Input DTOs, ports-only dependencies, and Fx decoration using ucdecorator.Wrap with fx.In/fx.Out.
---

# go-usecase

## Scope
Use this skill for any business operation use case in:
- `internal/modules/<module>/usecase/`

## Non-Negotiable Contracts

1. Naming is entity-first: `<Entity><Action>`.
2. Input validation is tag-based:
- Input fields must use `validate` tags.
- `Execute` must call `validator.Validate(input)`.
- Do not manually validate basic input fields (`== 0`, `== ""`, etc.).
3. Use cases depend on `ports.*` interfaces only.
4. No logging/metrics/tracing inside use case logic.
5. Fx wiring must expose decorated use cases through `fx.In` + `fx.Out` and `ucdecorator.Wrap`.

## Naming Rules (Exact)

Choose:
- `Entity` (PascalCase singular): `Page`, `ConnectorCredential`, `UserSession`
- `Action` (PascalCase verb/operation): `Create`, `Update`, `Delete`, `FindByID`, `FindAll`

Then enforce:

| Artifact | Pattern | Example (`Page` + `FindByID`) |
|---|---|---|
| File | `<entity_snake>_<action_snake>_usecase.go` | `page_find_by_id_usecase.go` |
| Input | `<Entity><Action>Input` | `PageFindByIDInput` |
| Output | `<Entity><Action>Output` | `PageFindByIDOutput` |
| Struct | `<Entity><Action>UseCase` | `PageFindByIDUseCase` |
| Constructor | `New<Entity><Action>UseCase` | `NewPageFindByIDUseCase` |

Invalid:
- `create_page_usecase.go`
- `CreatePageInput`
- `NewCreatePageUseCase`

## Required File Shape

Order is mandatory:
1. Input struct
2. Output struct
3. Use case struct
4. Constructor
5. `Execute`

## Input Validation Contract (Critical)

### Required pattern

```go
type PageFindByIDInput struct {
    PageID uint64 `validate:"required,gt=0"`
}

type PageFindByIDUseCase struct {
    pageRepo   ports.PageRepository
    validator  validator.Validator
}

func (uc *PageFindByIDUseCase) Execute(ctx context.Context, input PageFindByIDInput) (PageFindByIDOutput, error) {
    if err := uc.validator.Validate(input); err != nil {
        return PageFindByIDOutput{}, errs.ErrValidation
    }

    page, err := uc.pageRepo.FindByID(ctx, input.PageID)
    if err != nil {
        return PageFindByIDOutput{}, err
    }

    return PageFindByIDOutput{Page: page}, nil
}
```

### Forbidden pattern

```go
if input.PageID == 0 { ... }
if strings.TrimSpace(input.Slug) == "" { ... }
```

For normalized fields (example: trimmed slug), normalize first, then validate the normalized input struct.

Manual checks are allowed only for business invariants that tags cannot express (example: `ParentID != nil && *ParentID == PageID`).

## Use Case Template

```go
package usecase

import (
    "context"

    "github.com/cristiano-pacheco/bricks/pkg/validator"
    "github.com/cristiano-pacheco/<project>/internal/modules/<module>/ports"
)

type <Entity><Action>Input struct {
    Field string `validate:"required,max=255"`
}

type <Entity><Action>Output struct{}

type <Entity><Action>UseCase struct {
    repo      ports.<Entity>Repository
    validator validator.Validator
}

func New<Entity><Action>UseCase(
    repo ports.<Entity>Repository,
    validator validator.Validator,
) *<Entity><Action>UseCase {
    return &<Entity><Action>UseCase{
        repo:      repo,
        validator: validator,
    }
}

func (uc *<Entity><Action>UseCase) Execute(
    ctx context.Context,
    input <Entity><Action>Input,
) (<Entity><Action>Output, error) {
    if err := uc.validator.Validate(input); err != nil {
        return <Entity><Action>Output{}, err
    }

    _ = ctx
    return <Entity><Action>Output{}, nil
}
```

## Fx Wiring Contract (Critical)

Use raw constructors + decorated provider:

```go
type decorateUseCasesIn struct {
    fx.In

    Factory      *ucdecorator.Factory
    PageCreate   *usecase.PageCreateUseCase
    PageFindByID *usecase.PageFindByIDUseCase
}

type decorateUseCasesOut struct {
    fx.Out

    PageCreate   ucdecorator.UseCase[usecase.PageCreateInput, usecase.PageCreateOutput]
    PageFindByID ucdecorator.UseCase[usecase.PageFindByIDInput, usecase.PageFindByIDOutput]
}

func provideDecoratedUseCases(in decorateUseCasesIn) decorateUseCasesOut {
    return decorateUseCasesOut{
        PageCreate:   ucdecorator.Wrap(in.Factory, in.PageCreate),
        PageFindByID: ucdecorator.Wrap(in.Factory, in.PageFindByID),
    }
}

var Module = fx.Module(
    "<module>",
    fx.Provide(
        fx.Annotate(validator.New, fx.As(new(validator.Validator))),
        usecase.NewPageCreateUseCase,
        usecase.NewPageFindByIDUseCase,
        provideDecoratedUseCases,
    ),
)
```

## Final Checklist

- Naming follows `<Entity><Action>` everywhere.
- File name follows `<entity>_<action>_usecase.go`.
- Input fields have `validate` tags when validation is required.
- `Execute` calls `validator.Validate(input)`.
- No manual basic-input checks.
- Dependencies are only `ports.*` + validator + domain packages.
- No observability code in use case.
- Fx uses `fx.In`/`fx.Out` with `ucdecorator.Wrap`.
- `make lint`, `make nilaway`, and tests pass.
