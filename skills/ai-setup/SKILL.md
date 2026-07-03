---
name: ai-setup
description: Set up and health-check the ai-* skills' Obsidian integration. Use to set up, configure, verify, or troubleshoot ai-tools or its Obsidian connection — e.g. after installing with `npx skills add cristiano-pacheco/ai-tools`, or "is my Obsidian wired up?". Checks the MCP, the engineering/ root, and project detection.
---

You verify that the `ai-*` spec-driven workflow is ready to use and fix or report anything that's missing. The suite writes all generated documents into the user's Obsidian vault, grouped by project, so this skill confirms that pipe is connected end to end.

Run the checks below in order and finish with a short summary.

## 1. Obsidian MCP reachable

The suite reaches Obsidian through two pieces that must both be installed:

1. **Local REST API with MCP** — an Obsidian community plugin that exposes the vault over a local HTTP API. Install/enable it from Obsidian's community plugins, then copy its API key.
   Project: https://github.com/coddingtonbear/obsidian-local-rest-api
2. **mcp-obsidian** — the MCP server that bridges this agent to that REST API. Configure it as an MCP server with the plugin's API key and base URL.
   Project: https://github.com/MarkusPfundstein/mcp-obsidian

**Run a live test:** confirm the `mcp__mcp-obsidian__*` tools actually work by calling one of them — list the vault root with `obsidian_list_files_in_vault` (or `obsidian_get_recent_changes`). A successful response proves both pieces are wired up correctly.

If the call fails, the integration isn't connected. Tell the user to:
- install/enable the **Local REST API** plugin in Obsidian (link above) and make sure Obsidian is running,
- install and configure **mcp-obsidian** (link above) with the plugin's API key and base URL,
- then re-run this skill.

Don't continue the remaining checks until this live test passes — every other step depends on it.

## 2. Ensure the `engineering/` vault root

All suite output lives under `engineering/<project>/...`. Check whether `engineering/` exists with `obsidian_list_files_in_dir("engineering")`.

If it's missing, create the root index note at `engineering/index.md` with `obsidian_append_content` (writing a file creates its parent folder). This is the top of the Obsidian graph; the suite links every project up to it. Suggested content:

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
- ✅ / ❌ Obsidian MCP reachable
- ✅ / ❌ `engineering/` root present with `engineering/index.md` (created if it was missing)
- Resolved project base path for the current directory
- Which suite skills are available, and any that are missing

If everything is green, tell the user they can start with `ai-create-prd`. Otherwise, list exactly what to fix.
