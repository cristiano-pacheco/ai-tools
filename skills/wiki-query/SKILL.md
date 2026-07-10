---
name: wiki-query
description: Answer questions from a wiki.
disable-model-invocation: true
---

# Wiki Query

Use this skill when the wiki is the primary knowledge source and the goal is to answer from maintained pages rather than re-deriving everything from raw inputs.

## What this skill assumes

Look for a wiki workspace that contains:

- `AGENTS.md`
- `wiki/index.md`
- `wiki/log.md`
- one or more additional pages under `wiki/`

If several candidates exist, prefer the one nearest the files or subject the user mentioned. If none exists, say so briefly and ask for the target wiki root.

## First read

Before answering:

1. Read the wiki root `AGENTS.md`.
2. Read `wiki/index.md` first.
3. Read the most relevant wiki pages based on the index.
4. Read `wiki/overview.md` or `wiki/synthesis.md` when the question is broad, comparative, or cross-cutting.

Treat the local `AGENTS.md` as the source of truth. In this repository, the important query rules are:

- Treat `raw/` as immutable source material.
- Answer from the wiki first.
- Cite the relevant wiki pages and underlying sources when possible.
- If the result is durable, save it into `wiki/`.
- Update `wiki/index.md` and append a query entry to `wiki/log.md` when durable output is written back.
- Preserve contradictions and uncertainty instead of flattening them away.

## Query workflow

When answering a question:

1. Start from `wiki/index.md` to identify likely pages.
2. Read only the most relevant pages first; expand outward if needed.
3. Answer from the maintained wiki, not from guesswork.
4. Cite the specific wiki pages you relied on. If a page names or quotes a source, carry that provenance through when useful.
5. If the answer depends on contradictions, uncertainty, or incomplete coverage, state that clearly.
6. If the result seems durable, save it as a new or updated page in `wiki/`.
7. When durable output is written back, update `wiki/index.md` and append a query entry to `wiki/log.md`.

## What counts as durable output

Write back into `wiki/` when the result is likely to help future queries, such as:

- a synthesis that connects several existing pages
- a recurring question with a stable answer
- a new topical page that organizes scattered information
- a clarification page that captures an important contradiction, distinction, or open question

Do not create a new page for every small answer. Prefer updating an existing page when the new material fits naturally there.

## Writing guidance

- Prefer compact, navigable pages over chat-like transcripts.
- Preserve provenance and make it easy to trace claims back to pages and sources.
- Add cross-links to related pages.
- Match the repository's existing Markdown style.
- Keep `wiki/index.md` compact and scannable, with page links and one-line summaries.

## Citation guidance

- Cite relevant wiki pages directly in the response whenever possible.
- If the wiki already captures the underlying source, mention that provenance rather than re-reading all raw material by default.
- Only fall back to reading `raw/` when the wiki is clearly insufficient for the question and the user needs a deeper answer.

## Log format

When durable query output is written back, append a log entry with this heading format:

```md
## [YYYY-MM-DD] QUERY | Title
```

Match the surrounding log style for the body of the entry.

## Response expectations

After answering, give the user:

- the answer itself, grounded in the wiki
- citations to the wiki pages you used
- a brief note about any contradictions, uncertainty, or missing coverage
- if applicable, which wiki pages you created or updated and whether `wiki/index.md` and `wiki/log.md` were updated

## Example triggers

- "What does the wiki say about this topic?"
- "Answer this using the Obsidian wiki and cite the pages."
- "Synthesize the current state of the knowledge base on X."
- "If this answer is durable, save it back into the wiki."
