---
name: wiki-setup
description: Set up a new LLM wiki that follows the Karpathy-style `raw/` plus `wiki/` structure. Use this whenever the user asks to initialize, bootstrap, scaffold, or create a new wiki or Obsidian-style knowledge base, especially when they want the standard folder layout, starter files, and an `AGENTS.md` schema generated automatically.
---

# Wiki Setup

Use this skill to scaffold a fresh wiki workspace so future ingest, query, and lint work follows a consistent structure.

## Bundled resources

This skill includes reusable templates:

- `references/AGENTS.md`: the default wiki schema for new vaults
- `references/llm-wiki.md`: load this full file into context before scaffolding to capture the complete wiki pattern and setup intent
- `references/starter-files.md`: starter content for the core wiki pages

Read `references/AGENTS.md` and `references/starter-files.md`, and load the full `references/llm-wiki.md` into context before scaffolding.

## What to create

When setting up a new wiki, create this structure unless the user asks for a variation:

```text
<wiki-root>/
├── AGENTS.md
├── raw/
│   └── processed/
└── wiki/
    ├── index.md
    ├── log.md
    ├── overview.md
    └── synthesis.md
```

If the target folder already exists, inspect it first and only add missing pieces or repair obviously broken structure. Do not overwrite existing content unless the user clearly asked for regeneration.

## Setup workflow

1. Confirm or infer the target wiki root.
2. Create the folder structure:
   - `raw/`
   - `raw/processed/`
   - `wiki/`
3. Create `AGENTS.md` using `references/AGENTS.md`.
4. Create starter files in `wiki/` using `references/starter-files.md`:
   - `index.md`
   - `log.md`
   - `overview.md`
   - `synthesis.md`
5. If the user already has source material, leave it in `raw/` and do not modify those files.
6. Keep the initial content minimal and operational so later skills can take over cleanly.

## Completion checklist

Before saying setup is complete, verify each item:

- `AGENTS.md` exists at the wiki root.
- `AGENTS.md` matches the bundled schema unless the user requested a custom variant.
- `raw/` exists.
- `raw/processed/` exists.
- `wiki/` exists.
- `wiki/index.md` exists.
- `wiki/log.md` exists.
- `wiki/overview.md` exists.
- `wiki/synthesis.md` exists.
- starter file contents were created only for missing files or for files the user explicitly asked to regenerate.
- no existing source files in `raw/` were modified.
- the final response lists what was created and what was preserved.

If any checklist item fails, fix it before concluding or tell the user exactly what remains incomplete.

## Setup rules

- Treat `raw/` as the place for immutable source material.
- Treat `wiki/` as the maintained knowledge base.
- Keep starter files compact and easy to extend.
- Match the bundled schema unless the user asks for a custom variation.
- Do not fabricate topical content during setup. Create structure and placeholders, not pretend knowledge.

## Content guidance

- `AGENTS.md` should define the maintenance schema and workflows.
- `wiki/index.md` should explain that it is the compact catalog of pages.
- `wiki/log.md` should explain the log entry format and may include an initial setup entry if useful.
- `wiki/overview.md` should be a high-level orientation placeholder.
- `wiki/synthesis.md` should be a cross-source synthesis placeholder.

## When to add an initial log entry

If you created the wiki from scratch, it is helpful to append an initial setup entry to `wiki/log.md` so the vault has an explicit starting point. Use the same heading convention as the schema and label it `QUERY` only if the user asked for content work; otherwise prefer a plain setup note inside the starter file template.

## Response expectations

After setup, tell the user:

- where the wiki was created
- which folders and files were created
- whether any existing files were preserved instead of overwritten
- any follow-up suggestions, such as placing source material in `raw/` or running an ingest pass next

## Example triggers

- "Set up a new wiki for this project."
- "Bootstrap an Obsidian-style LLM wiki here."
- "Create the standard wiki folder structure and AGENTS.md."
- "Initialize a new knowledge base with the same schema as this repo."
