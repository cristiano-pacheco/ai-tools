---
name: ai-import-vault
description: Import an existing legacy ai/ directory (PRDs, tech specs, tasks, archive, PRs, reviews) into Obsidian under the engineering/<project>/ layout, so pre-existing work isn't lost when adopting the ai-* skills. Use when the user wants to migrate, import, backfill, or move an old ai/ folder into the vault — run once per repo. Handles ai/archive/ containing many features.
---

# Import legacy ai/ content into the Obsidian vault

The ai-* skills write to Obsidian going forward, but most repos already have a local `ai/` directory full of PRDs, tech specs, task lists, archived features, PR write-ups, and reviews. This skill migrates that existing content into the same `engineering/<project>/...` layout so nothing is lost. Run it **once per repository**.

It is a one-time, additive migration: it reads local files and writes them to the vault. It never deletes or edits the local `ai/` directory.

## Resolve the project

1. Run `git rev-parse --show-toplevel`; the basename is the project name.
2. If the current directory is not a git repo, propose a name from `basename "$PWD"` (kebab-cased) and **confirm with the user**.
3. Everything imports under `engineering/<project>/`.

## How it maps

A bundled script produces a deterministic source → target plan. The mapping and name normalization (lowercase, `_`→`-`, `techspec`→`tech-spec`):

| Legacy source | Vault target |
|---|---|
| `ai/tasks/<feature>/<file>` | `engineering/<project>/<feature>/<file>` |
| `ai/archive/<rel>` (feature subfolders **and** loose docs) | `engineering/<project>/archive/<rel>` |
| `ai/pull-requests/<file>` | `engineering/<project>/pull-requests/<file>` |
| `ai/code-reviews/<rel>` | `engineering/<project>/code-reviews/review-<flattened-rel>` |
| `ai/codebase-review/<file>` | `engineering/<project>/codebase-reviews/<file>` |

`ai/commands/`, `ai/templates/`, `ai/docs/`, and `ai/plans/` are **skipped** — they are tooling or non-content, not documents to import.

`ai/archive/` typically holds **many** features (each its own `prd-<feature>/` folder) plus loose one-off docs; they all land under `engineering/<project>/archive/`, preserving their subfolders.

## Workflow

### 1. Generate the plan

Run the bundled script against the repo's `ai/` directory (default `./ai`; ask the user if it lives elsewhere):

```bash
bash <skill-dir>/scripts/plan-import.sh ./ai <project>
```

It prints tab-separated `SOURCE<TAB>VAULT_TARGET` lines. Read them into a list.

### 2. Present a summary and confirm

Show the user how many files will be imported, grouped by target area (features, archive, pull-requests, code-reviews, codebase-reviews), and a few example mappings. Wait for confirmation before writing anything.

### 3. Import each file

For every `SOURCE → TARGET` pair:

1. Check whether `TARGET` already exists with `obsidian_get_file_contents`.
   - **If it exists, skip it by default** (don't clobber). Only overwrite if the user asked to — then `obsidian_delete_file` (pass `confirm: true`) and re-create.
2. Read the local `SOURCE` file's content.
3. Write it with `obsidian_append_content(TARGET, content)` — this creates intermediate folders automatically.

Import in batches and keep a running count. There can be 100+ files, so don't stop partway — work through the whole plan.

### 4. Report

Summarize: how many files imported, how many skipped (already present), and any sources you couldn't map. Give the top-level vault path (`engineering/<project>/`).

## Gotchas

- **Run once per repo.** Project = repo basename, so importing each repo's `ai/` separately keeps content grouped correctly. To migrate several projects, run the skill in each.
- **File names are normalized, file *contents* are not.** Internal references inside old docs (e.g. a task file saying "read `techspec.md` in this folder") keep their original wording even though the imported file is `tech-spec.md`. These are historical/archived docs — leave the content as-is rather than rewriting cross-references.
- **Re-running is safe.** Existing targets are skipped by default, so a second run only fills in what's missing.
- **The local `ai/` directory is never modified or deleted** — after a successful import the user can remove it manually if they want.
