---
name: wiki-lint
description: Lint and maintain an LLM wiki that follows the Karpathy-style `raw/` plus `wiki/` structure. Use this whenever the user asks to audit the wiki, check for contradictions, find stale or orphaned pages, improve cross-linking, identify missing topic pages, or surface gaps that suggest useful future sources.
---

# Wiki Lint

Use this skill to inspect the health of a maintained wiki and turn structural or knowledge gaps into clear, durable improvements.

## What this skill assumes

Look for a wiki workspace that contains:

- `AGENTS.md`
- `wiki/index.md`
- `wiki/log.md`
- one or more additional pages under `wiki/`

If multiple candidates exist, prefer the one closest to the files or subject the user mentioned. If none exists, say so briefly and ask for the target wiki root.

## First read

Before linting:

1. Read the wiki root `AGENTS.md`.
2. Read `wiki/index.md` to understand the current page map.
3. Read `wiki/overview.md` and `wiki/synthesis.md` because they often expose cross-page drift.
4. Sample the most relevant topical pages based on the user’s concern, or broaden the pass if the user asked for a full lint.
5. Inspect recent entries in `wiki/log.md` to understand recent ingest, query, and maintenance activity.

Treat the local `AGENTS.md` as the source of truth. In this repository, linting should check for:

- contradictions between pages
- stale claims superseded by newer sources
- orphan pages with weak linkage
- important ideas mentioned but lacking their own page
- missing cross-references
- gaps that suggest useful future sources

Record each lint pass in `wiki/log.md`.

## Lint workflow

1. Start from `wiki/index.md` to understand the shape of the wiki.
2. Inspect `overview.md`, `synthesis.md`, and the most relevant topical pages.
3. Look for contradictions, stale claims, orphan pages, missing pages, missing cross-links, and source gaps.
4. When a fix is straightforward and clearly within scope, update the relevant wiki pages directly.
5. Update `wiki/index.md` if a page is created or materially changes scope.
6. Append a lint entry to `wiki/log.md`.
7. Summarize what you fixed, what remains uncertain, and what follow-up work would help.

## How to evaluate findings

Prefer actionable findings over vague criticism.

- For contradictions, name the pages involved and describe the exact tension.
- For stale claims, explain what appears outdated and what newer source or page supersedes it.
- For orphan pages, identify weak inbound or outbound linkage and suggest or add useful cross-links.
- For missing topic pages, point to the pages where the concept already appears and explain why it deserves its own page.
- For future-source gaps, name the missing evidence or perspective that would reduce uncertainty.

## Editing guidance

- Preserve contradictions and uncertainty explicitly instead of smoothing them over.
- Prefer targeted edits over broad rewrites unless the wiki structure is clearly broken.
- Add durable knowledge to `wiki/`, not only to the chat response.
- Never modify files inside `raw/`; treat them as immutable source material.
- Match the repository’s existing Markdown style.
- Keep `wiki/index.md` compact and scannable, with grouped page links and one-line summaries.

## Log format

Every lint pass should append an entry to `wiki/log.md` using this heading format:

```md
## [YYYY-MM-DD] LINT | Title
```

Match the surrounding log style for the body of the entry.

## Response expectations

After the lint pass, give the user:

- the most important findings
- which wiki pages you updated or created, if any
- whether `wiki/index.md` and `wiki/log.md` were updated
- any unresolved contradictions, uncertainty, or source gaps
- the highest-value next steps if more cleanup would help

## Example triggers

- "Lint the wiki for contradictions and stale claims."
- "Find orphan pages and missing cross-links in this knowledge base."
- "Audit the Obsidian wiki and tell me what needs cleanup."
- "Check whether the wiki is missing pages for important recurring ideas."
