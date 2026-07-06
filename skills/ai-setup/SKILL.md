---
name: ai-setup
description: Set up and health-check the ai-* skills' Obsidian integration. Use to set up, configure, verify, or troubleshoot ai-tools or its Obsidian connection — e.g. after installing with `npx skills add cristiano-pacheco/ai-tools`, or "is my Obsidian wired up?". Checks the vault directory, the engineering/ root, and project detection.
---

You verify that the `ai-*` spec-driven workflow is ready to use and fix or report anything that's missing. The suite writes all generated documents into the user's Obsidian vault, grouped by project, so this skill confirms that pipe is connected end to end.

Run the checks below in order and finish with a short summary.

## 1. Vault reachable

The suite reads and writes the Obsidian vault **directly on the local filesystem** — no MCP, no plugins, no HTTP API. It just needs the vault directory to exist and be writable.

**Vault root (default):** `$HOME/Documents/obsidian/obsidian` (i.e. `~/Documents/obsidian/obsidian`). If the user's vault lives elsewhere, they can tell any ai-* skill a different absolute path.

**Run a live test:** confirm the vault directory exists and is writable:

```bash
test -d "$HOME/Documents/obsidian/obsidian" && test -w "$HOME/Documents/obsidian/obsidian" && echo OK
```

If it doesn't print `OK`, the vault isn't where expected. Tell the user to either create the directory, point Obsidian's vault there, or supply the correct absolute vault path — then re-run this skill.

Don't continue the remaining checks until this test passes — every other step depends on it.

## 2. Ensure the `engineering/` vault root

All suite output lives under `<vault>/engineering/<project>/...`. Check whether it exists: `test -d "$HOME/Documents/obsidian/obsidian/engineering"`.

If it's missing, create the root index note at `<vault>/engineering/index.md` with the `Write` tool (it creates the parent folder). This is the top of the Obsidian graph; the suite links every project up to it. Suggested content:

```markdown
# Engineering

AI-generated engineering documents, grouped by project (repository).
Each project folder holds feature specs (prd.md, tech-spec.md, tasks.md, ...),
plus pull-requests/, code-reviews/, and codebase-reviews/.

## Projects
```

The `## Projects` list is filled as projects appear (each skill links its project here, and `ai-reindex` rebuilds the whole thing). If a legacy `engineering/README.md` exists from an older setup, leave it — but `index.md` is now the canonical root.

## 3. Verify project detection

The suite names the project from the git repository:
- Run `git rev-parse --show-toplevel`; the basename is the project name, so the base path is `engineering/<basename>`.
- If the current directory is not a git repo, the skills fall back to proposing a name from `basename "$PWD"` and asking for confirmation.

Report the resolved base path for the current directory (or, if there's no git repo here, state that the no-git fallback will apply).

## 4. Confirm the suite is available

The spec-driven suite is:

- `ai-create-prd` — PRD → `engineering/<project>/workplans/<feature>/prd.md`
- `ai-create-techspec` — tech spec → `workplans/<feature>/tech-spec.md`
- `ai-review-techspec` — architect review → `workplans/<feature>/tech-spec-review.md`
- `ai-create-tasks` — task list → `workplans/<feature>/tasks.md` + `NN-task.md`
- `ai-execute-task` — implement in repo; notes → `workplans/<feature>/implementation-notes.md`
- `ai-create-pr` — PR description → `<project>/pull-requests/<branch>.md`
- `ai-code-review` — branch review → `<project>/code-reviews/review-<branch>.md`
- `ai-codebase-review` — codebase audit → `<project>/codebase-reviews/<system>.md`
- `ai-reindex` — rebuild the wikilink graph (root, per-project, and per-feature `index.md`)

Every skill above cross-links its output and maintains three tiers of `index.md`
(`engineering/index.md`, `engineering/<project>/index.md`, and
`engineering/<project>/workplans/<feature>/index.md`) so the notes form a
connected Obsidian graph. `ai-reindex` regenerates all of them deterministically.

Check which of these you can see in your available skills and flag any that are missing. If skills are missing, the user can install the full suite with:

```bash
npx skills add cristiano-pacheco/ai-tools
```

## 5. Summary

Print a short report:
- ✅ / ❌ Vault directory reachable and writable
- ✅ / ❌ `engineering/` root present with `engineering/index.md` (created if it was missing)
- Resolved project base path for the current directory
- Which suite skills are available, and any that are missing

If everything is green, tell the user they can start with `ai-create-prd`. Otherwise, list exactly what to fix.
