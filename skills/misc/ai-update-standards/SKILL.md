---
name: ai-update-standards
description: "Record session corrections in CODING_STANDARDS.md."
disable-model-invocation: true
---

Update @CODING_STANDARDS.md from confirmed violations and accepted corrections in this session.

## Process

1. Read the installed `unslop/SKILL.md`. Stop if unavailable.
2. Extract reusable rules from the corrections. Ask about uncertain corrections. If none qualify, leave the file unchanged.
3. Read the supplied standards file or the repo's root `CODING_STANDARDS.md`. Create it if absent. Ask if the target is ambiguous or a correction conflicts with an existing rule.
4. Add missing rules or clarify existing ones in place. Preserve clear rules and unrelated content. Apply `unslop`, save, and check the diff for duplicate rules. Report what changed or was already covered.

## Rule format

Reuse existing topics. Write one bullet per requirement in the file's language. State the required behavior, its scope, and necessary exceptions in the fewest clear sentences.

```markdown
## Go

- Keep function and method results unnamed.
```

Include conditions only when they limit the rule's scope. Omit dates, incident narratives, and configuration already expressed by tooling.
