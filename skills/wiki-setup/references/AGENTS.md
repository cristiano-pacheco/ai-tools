# LLM Wiki Schema

This vault follows Karpathy's LLM Wiki pattern.

## Architecture

There are three layers:

1. `raw/` contains immutable source material. The LLM may read from this directory but must never modify files inside it.
2. `wiki/` contains the maintained markdown knowledge base. The LLM owns this layer and may create, revise, cross-link, and reorganize pages as needed.
3. `AGENTS.md` is the schema for how this wiki is maintained.

## Directory Structure

- `raw/`: source documents and assets
- `wiki/index.md`: content-oriented catalog of wiki pages
- `wiki/log.md`: append-only chronological log of ingest, query, and lint activity
- `wiki/overview.md`: high-level orientation page for the subject area
- `wiki/synthesis.md`: evolving current synthesis across sources
- `wiki/`: additional markdown pages created and maintained over time

## Operating Rules

1. Treat `raw/` as the source of truth and keep it immutable.
2. Write all durable knowledge into `wiki/`, not only into chat responses.
3. Update `wiki/index.md` whenever a new wiki page is created or an existing page materially changes scope.
4. Append a new entry to `wiki/log.md` for every ingest, durable query output, and lint pass.
5. Prefer cross-links between related wiki pages.
6. Preserve contradictions and uncertainty explicitly instead of smoothing them over.

## Workflows

### Ingest

When a new source is added to `raw/`:

1. Read the source.
2. Create or update a summary page in `wiki/`.
3. Update any affected pages in `wiki/`, including `wiki/overview.md` and `wiki/synthesis.md` when relevant.
4. Update `wiki/index.md`.
5. Append an ingest entry to `wiki/log.md`.
6. Move the source file from raw/ directory to raw/processed/

### Query

When answering questions:

1. Read `wiki/index.md` first.
2. Read the most relevant wiki pages.
3. Answer from the wiki with citations to the relevant pages and sources when possible.
4. If the result is durable, save it as a page in `wiki/`.
5. Update `wiki/index.md` and append a query entry to `wiki/log.md` when durable output is written back.

### Lint

Periodically check for:

- contradictions between pages
- stale claims superseded by newer sources
- orphan pages with weak linkage
- important ideas mentioned but lacking their own page
- missing cross-references
- gaps that suggest useful future sources

Record each lint pass in `wiki/log.md`.

## Index Format

`wiki/index.md` should stay compact and scannable. Group pages by category. Each entry should include:

- page link
- one-line summary

## Log Format

Every entry in `wiki/log.md` should begin with:

`## [YYYY-MM-DD] TYPE | Title`

Where `TYPE` is typically `INGEST`, `QUERY`, or `LINT`.
