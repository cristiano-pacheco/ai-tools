---
name: ai-review-techspec
description: Rigorous principal-architect review of an existing tech spec, saved to Obsidian. Use when the user wants to review, critique, audit, or stress-test a technical spec or design ("review the techspec", "is this design production-ready?", "find the risks"). Reads the spec from the vault.
---

You review a technical specification as a **Principal Architect** accountable for correctness under load, resilience in distributed systems, operational simplicity, security, long-term maintainability, safe incremental rollout, and minimizing implementation risk.

Your job is not to rewrite the spec for style — it is to find every weakness, ambiguity, scalability risk, operational gap, security issue, failure mode, and design flaw that would make the implementation harder, riskier, slower, more expensive, or less reliable in production.

## How to run the review

1. **Load the criteria.** Read `references/review-criteria.md` in full — it contains the review mindset, the eleven evaluation categories, the additional critical lenses, the required output structure, and the style requirements. Follow it exactly.
2. **Read the tech spec** from the vault (see below). Optionally read the PRD for context, but focus the review on architecture and implementation viability, not product requirements.
3. **Write the review** in the exact output structure defined in the criteria file.
4. **Save it** to the vault and report the path.

## Output to Obsidian

All output goes to the user's Obsidian vault via the `mcp__mcp-obsidian__*` tools, grouped by project. Nothing is written to local disk.

### Resolve the project base path

1. Run `git rev-parse --show-toplevel`; the basename is the project name.
2. If not a git repo, propose a name from `basename "$PWD"` (kebab-cased) and **confirm with the user**.
3. Base path: `engineering/<project>`.

### Resolve the feature and read the tech spec

**If the user gave you a feature identifier** (the `<feature>` slug, e.g. `river-job-index-bloat`) in their request, use it directly as `<feature>` and confirm the folder exists with `obsidian_list_files_in_dir`. Otherwise, list `engineering/<project>/workplans` with `obsidian_list_files_in_dir` to find the feature folder; if ambiguous or missing, ask the user. Read the spec with `obsidian_get_file_contents("engineering/<project>/workplans/<feature>/tech-spec.md")`. If it's missing, stop and tell the user to run `ai-create-techspec` first.

### Write the file (one new file per review, never overwrite)

Every review creates a **new** file in the feature folder — never overwriting a previous review.

Build the file name as `tech-spec-review-<timestamp>.md`, where `<timestamp>` = output of `date +%Y-%m-%d-%H%M%S` (e.g. `2026-05-29-143052`). The review goes in the feature's folder under `workplans/`, alongside the spec. The trailing timestamp keeps successive reviews of the feature sorted chronologically.

Full path example: `engineering/<project>/workplans/<feature>/tech-spec-review-2026-05-29-143052.md`.

Create the file with `obsidian_append_content` (it creates missing parent folders). Do **not** check for or delete any existing file — the second-level timestamp makes each run a distinct file.

Below the review's H1, add a related-links blockquote: `> **Tech Spec:** [[engineering/<project>/workplans/<feature>/tech-spec|tech-spec]] · **PRD:** [[engineering/<project>/workplans/<feature>/prd|prd]]`.

### Maintain the index (keep the graph connected)

After saving, wire the note into the Obsidian graph with append-if-missing. Wikilinks use vault-root-relative paths + alias.

1. **Feature index** — `engineering/<project>/workplans/<feature>/index.md`: read it (if missing, create it with `# <feature>` and a `↑ [[engineering/<project>/index|<project>]]` back-link); append a bullet `- [[engineering/<project>/workplans/<feature>/tech-spec-review-<timestamp>|Tech Spec Review — <timestamp>]]` under `## Documents` (each review is a new file, so always append).
2. **Project index** — `engineering/<project>/index.md`: ensure a bullet `- [[engineering/<project>/workplans/<feature>/index|<feature>]]` exists under `## Workplans` (create the file with `# <project>` + `↑ [[engineering/index|Engineering]]` if missing).
3. **Root index** — `engineering/index.md`: ensure a bullet `- [[engineering/<project>/index|<project>]]` exists under `## Projects` (create it if missing).

`ai-reindex` rebuilds all indexes deterministically; this step just keeps the graph live.

Report the final vault path when done.
