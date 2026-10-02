---
name: commit
description: Commit staged changes using Conventional Commits.
disable-model-invocation: true
---

Commit the existing index without pausing for approval. Stage files only when explicitly asked. Never add a `Co-Authored-By` trailer.

## Workflow

1. Read `git diff --cached --stat`, `git diff --cached`, and `git log --oneline -5`. If the index is empty, report it and stop.
2. Check every staged file and the full diff for secrets. If a file likely contains secrets, such as `.env`, credentials, tokens, or keys, abort and warn the user.
3. Write a Conventional Commit message using the format below. For mixed changes, choose the most significant type. Follow recent commit style within these rules.
4. Run `git commit -m "<message>"`, preserving any body line breaks, and report the result.

## Message format

```text
<type>[optional scope][!]: <description>

<optional body>
```

- Choose from `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`, or `lint`.
- Put the scope in parentheses when the affected module, package, or area is clear, as in `fix(auth): ...`. Add `!` after the type or scope for breaking changes.
- Use a concise, lowercase, imperative description with no final period.
- Include a body only for complex or non-obvious changes. Explain what changed and why, wrapping at 72 characters.
