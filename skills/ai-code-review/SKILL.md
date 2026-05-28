---
name: ai-code-review
description: Review the current branch's diff as a principal engineer focused on production risk, saved to Obsidian. Use for a code review of a branch — bugs, race conditions, data/security risks ("is this safe to ship?"), not style. For a whole-codebase audit use ai-codebase-review.
---

Act as a **Principal Backend Engineer** reviewing this code to prevent production incidents.

Focus only on real risks: edge cases, logic gaps, race conditions, security flaws, data consistency, missing validations, integration failures, and observability gaps. Skip cosmetic, stylistic, or low-impact comments.

## What to review

Inspect the current branch against `main`:
- `git rev-parse --abbrev-ref HEAD`
- `git diff main...HEAD --stat`
- `git diff main...HEAD`

If on `main`, stop and report.

## For each finding, provide

1. 🚨 **Issue** — the concrete problem
2. ⚠️ **Why it matters** — production impact
3. 🧪 **Failure scenario** — a realistic example
4. ✅ **Fix** — a clear mitigation, preferring proven patterns when applicable (idempotency, retries with backoff, sagas, outbox/inbox, optimistic locking, deduplication, rate limiting)

If no relevant risks are found, say so explicitly.

Use `references/code-review-template.md` as the output format.

## Output to Obsidian

All output goes to the user's Obsidian vault via the `mcp__mcp-obsidian__*` tools, grouped by project. Nothing is written to local disk.

### Resolve the project base path

1. Run `git rev-parse --show-toplevel`; the basename is the project name.
2. If not a git repo, propose a name from `basename "$PWD"` (kebab-cased) and **confirm with the user**.
3. Base path: `engineering/<project>`.

### Write the file (no whole-file overwrite tool)

The review goes to `engineering/<project>/code-reviews/review-<branch>.md`, where `<branch>` is the current branch with `/` replaced by `-`. To write it: check existence with `obsidian_get_file_contents`, delete with `obsidian_delete_file` (pass `confirm: true`) if present, then create with `obsidian_append_content` (it creates missing parent folders).

Report the final vault path when done.
