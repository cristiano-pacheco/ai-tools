---
name: wiki-ingest
description: Ingest sources into a wiki.
disable-model-invocation: true
---

# Wiki Ingest

Use this skill to turn source documents into durable wiki knowledge instead of leaving the work only in chat.

## What this skill assumes

Look for a wiki workspace that contains:

- `AGENTS.md`
- `raw/`
- `wiki/`

If more than one candidate exists, prefer the one closest to the files the user mentioned. If none exists, say so briefly and fall back to asking the user for the target wiki root.

## First read

Before making changes:

1. Read the wiki root `AGENTS.md`.
2. Read `wiki/index.md`.
3. Read `wiki/overview.md` and `wiki/synthesis.md` if the source looks broad enough to affect them.
4. Inspect `wiki/log.md` to match the existing log style.

Treat the local `AGENTS.md` as the source of truth for the workflow. In this repository, the key rules are:

- Never modify files inside `raw/`; treat them as immutable source material.
- Write durable knowledge into `wiki/`, not only into the chat response.
- Update `wiki/index.md` whenever a page is created or materially changes scope.
- Append a log entry to `wiki/log.md` for every ingest.
- Preserve contradictions and uncertainty explicitly instead of smoothing them over.
- Prefer cross-links between related wiki pages.

## Ingest workflow

When a new source is added to `raw/`:

1. Read the source carefully.
2. Create or update the most relevant summary page in `wiki/`.
3. Update any affected pages in `wiki/`.
4. Update `wiki/overview.md` when the new source changes high-level orientation.
5. Update `wiki/synthesis.md` when the new source changes the evolving cross-source picture.
6. Update `wiki/index.md` with compact, scannable entries that include:
   - page link
   - one-line summary
7. Append an ingest entry to `wiki/log.md` using this heading format:

```md
## [YYYY-MM-DD] INGEST | Title
```

8. If the repo workflow explicitly requires it, move processed files from `raw/` to `raw/processed/`. Do not do this if it would violate the repo's immutability rule or if the destination does not exist and the user did not ask for file movement.

## Writing guidance

- Prefer adding or revising a small number of durable pages over scattering duplicated notes.
- Preserve provenance. Make it clear which claims came from which source.
- Preserve uncertainty, disagreements, and open questions explicitly.
- Add useful cross-links to existing pages.
- Keep `wiki/index.md` compact and easy to scan.
- Match the repository's existing Markdown style instead of inventing a new format.

## Source handling rules

- Never edit the contents of source files in `raw/`.
- If the ingest request refers to a specific source file, focus on that file first rather than trying to reprocess the whole vault.
- If a source appears already ingested, update the relevant wiki pages only if the new pass materially improves coverage, structure, or cross-linking.

## Response expectations

After completing the ingest, give the user a short summary that includes:

- which source you processed
- which wiki pages you created or updated
- whether `wiki/index.md` and `wiki/log.md` were updated
- any contradictions, uncertainty, or follow-up gaps worth noting

## Example triggers

- "Ingest the new PDF in `raw/` into the wiki."
- "Summarize this source and fold it into the Obsidian wiki."
- "Process the latest raw notes and update the knowledge base."
- "Add this article to the wiki and update the synthesis."
