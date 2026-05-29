---
name: ai-codebase-review
description: Surgical, evidence-based audit of a whole codebase for the few issues that hurt scalability, reliability, correctness, latency, DB load, or cost — saved to Obsidian. Use for a codebase review, architecture audit, or "where are the production bottlenecks?". For a single branch diff use ai-code-review.
---

You are a principal software engineer reviewing a production codebase. Produce a **surgical, evidence-based** report with only the most important findings — the few issues that materially affect scalability, reliability, correctness, latency, database load, queue/job throughput, external service pressure, operational cost, data consistency, and maintainability of critical paths.

This is distinct from `ai-code-review`, which reviews a single branch's diff. This skill scans the whole codebase (or a named flow/system within it).

## How to run the review

1. **Load the method and format.** Read `references/report-format.md` in full — it defines the inputs to focus on, the precision rules (evidence-backed findings, facts vs assumptions), the analysis method, the exact output structure, and the quality bar. Follow it exactly.
2. **Analyze the repository** currently available. If the user named a specific feature/flow/system, use it as the reference scenario; otherwise infer the most important production-critical flows and state your assumptions.
3. **Write the report** in the exact structure from the format file. Keep it to a maximum of 5 findings (prefer 2–4).
4. **Save it** to the vault and report the path.

## Output to Obsidian

All output goes to the user's Obsidian vault via the `mcp__mcp-obsidian__*` tools, grouped by project. Nothing is written to local disk.

### Resolve the project base path

1. Run `git rev-parse --show-toplevel`; the basename is the project name.
2. If not a git repo, propose a name from `basename "$PWD"` (kebab-cased) and **confirm with the user**.
3. Base path: `engineering/<project>`.

### Write the file (one new file per review, never overwrite)

Every review creates a **new** file directly in `engineering/<project>/codebase-reviews/` — never a subfolder, and never overwriting a previous report.

Build the file name as `<timestamp>-<system>.md`:

1. `<timestamp>` = output of `date +%Y-%m-%d-%H%M%S` (e.g. `2026-05-29-143052`). The leading timestamp keeps the folder sorted chronologically.
2. `<system>` = a kebab-case slug for the feature/system reviewed (e.g. `dispatch-hot-path`), with every character outside `[A-Za-z0-9._-]` replaced by `-`.

Full path example: `engineering/<project>/codebase-reviews/2026-05-29-143052-dispatch-hot-path.md`.

Create the file with `obsidian_append_content` (it creates missing parent folders). Do **not** check for or delete any existing file — the second-level timestamp makes each run a distinct file.

Report the final vault path when done.
