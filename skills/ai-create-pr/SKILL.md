---
name: ai-create-pr
description: Write a Pull Request title and description for the current branch, saved to Obsidian. Use when the user wants a PR description or summary, or to "describe this branch for review" / "write up my changes for the PR". Inspects the diff vs main and writes short, plain, and human.
---

You write a Pull Request title and description for the current branch (vs. `main`) so a reviewer understands the change without opening the diff.

Goal: **short, plain, human** — like a teammate explaining the PR in chat, not a corporate write-up.

<critical>EXPLORE THE BRANCH DIFF FIRST.</critical>
<critical>WRITE LIKE A HUMAN — SHORT, PLAIN, NO PADDING.</critical>
<critical>NEVER INVENT METRICS, CONFIGS, MIGRATIONS, OR ENDPOINTS — ONLY CITE WHAT IS IN THE DIFF.</critical>

## Voice and length

- **Aim for under 250 words total.** If you're over, you're padding.
- Write like a person. Contractions are fine. Cut phrases like "this PR introduces", "in order to", "going forward", "at production scale".
- Short sentences. Bullets over paragraphs. One line per bullet.
- Cite specifics (file paths, table names, metric names). Drop the prose around them.
- A section with nothing real to say is worse than no section — delete it.

## What to produce

1. A **title** in Conventional Commits: `<type>: <imperative summary>`. Types: `feat`, `fix`, `chore`, `refactor`, `perf`, `docs`, `test`, `build`, `ci`, `style`, `revert`. Scope optional (`feat(renderer): ...`). No leading emoji.
2. A **description** that answers *Why? How? What can break?* — and nothing else.
3. The PR document, saved to the vault (see below).

## Output to Obsidian

All output goes to the user's Obsidian vault via the `mcp__mcp-obsidian__*` tools, grouped by project. Nothing is written to local disk.

### Resolve the project base path

1. Run `git rev-parse --show-toplevel`; the basename is the project name.
2. If not a git repo, propose a name from `basename "$PWD"` (kebab-cased) and **confirm with the user**.
3. Base path: `engineering/<project>`.

### Write the file (no whole-file overwrite tool)

The PR doc goes to `engineering/<project>/pull-requests/<branch>.md`, where `<branch>` is the current branch with `/` replaced by `-`. To write it: check existence with `obsidian_get_file_contents`, delete with `obsidian_delete_file` (pass `confirm: true`) if present, then create with `obsidian_append_content` (it creates missing parent folders).

## Workflow

### 1. Inspect the branch
Run in parallel:
- `git rev-parse --abbrev-ref HEAD`
- `git log main..HEAD --oneline`
- `git diff main...HEAD --stat`
- `git diff main...HEAD` (read selectively — skip tests and generated files first pass)

If on `main`, stop and report.

### 2. Pick one archetype

| Archetype | Keep these sections |
|---|---|
| `feat` | Why · How · Key points · Surface area · Observability (only if metrics added) |
| `perf` | Why · How · Key points · Observability |
| `fix` | Why · Root cause · Fix |
| `refactor` | Why · What changed · Migration notes (only if breaking) |
| `docs` | Why · What changed |

Borrow other sections only when there's real content. Skip the rest.

### 3. Extract facts from the diff

- New/changed HTTP or gRPC endpoints
- New migrations, tables, columns
- New config keys (`config/`, `*.yaml`, `Bind*`)
- New metrics (`metrics.gen.yaml`)
- Behavioral changes (retry, idempotency, ordering)

If a fact isn't in the diff, don't write it.

### 4. Write the PR

Use `references/pr-template.md` for structure.

- **Hero line**: one short sentence — what changed, what it unlocks. Lead with the archetype emoji (🚀 feat · ⚡ perf · 🐛 fix · 🧱 refactor · 🛡️ security · 📚 docs).
- **Why**: 2–3 sentences. The pain. Plain English.
- **How**: a short paragraph. When behavior shifts, show **before vs. after** — side-by-side bullets or a diagram.
- **Diagrams**: always `mermaid`. Prefer `flowchart`, `stateDiagram-v2`, or `classDiagram` over `sequenceDiagram`. Use a sequence diagram only when ordering across multiple actors is the actual point. Skip diagrams for trivial changes.
- **Make diagrams dead simple** — grokable in under 5 seconds. Few nodes (≤7). Plain labels. One clear flow. If you can't make it that simple, use a bullet list.
- **Key points**: 3–6 emoji bullets, one line each — the properties a reviewer needs (correctness, blast radius, idempotency).
- Tables only for enumerable facts (config keys, retry boundaries). Never for narrative.

### 5. Save and report

Save to `engineering/<project>/pull-requests/<branch>.md`. Report the path and the title.

## Don't do these

- ❌ Multi-line bullets that read like paragraphs
- ❌ "This PR aims to..." / "In order to..." / "Going forward..."
- ❌ Listing every file you touched
- ❌ Inventing alerts, dashboards, or metrics
- ❌ A "Migration / rollout" section when nothing is breaking
- ❌ Restating the same fact in three sections
- ❌ Filler adjectives ("crisp", "robust", "production-grade")

## Checklist (one pass before saving)

- [ ] Diff inspected
- [ ] Title is Conventional Commits, no emoji
- [ ] Description under ~250 words
- [ ] Reads like a person wrote it
- [ ] Every fact is in the diff
- [ ] Empty sections deleted
- [ ] Saved to `engineering/<project>/pull-requests/<branch>.md`
