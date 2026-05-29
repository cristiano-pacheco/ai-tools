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

### Write the file (one new file per review, never overwrite)

Every review creates a **new** file directly in `engineering/<project>/code-reviews/` — never a subfolder, and never overwriting a previous review.

Build the file name as `<timestamp>-<branch>.md`:

1. `<timestamp>` = output of `date +%Y-%m-%d-%H%M%S` (e.g. `2026-05-29-143052`). The leading timestamp keeps the folder sorted chronologically.
2. `<branch>` = the current branch with every character outside `[A-Za-z0-9._-]` replaced by `-` (so `/` becomes `-`). Example: `cristiano-pacheco/add-communication-flows` → `cristiano-pacheco-add-communication-flows`.

Full path example: `engineering/<project>/code-reviews/2026-05-29-143052-cristiano-pacheco-add-communication-flows.md`.

Create the file with `obsidian_append_content` (it creates missing parent folders). Do **not** check for or delete any existing file — the second-level timestamp makes each run a distinct file.

Report the final vault path when done.
