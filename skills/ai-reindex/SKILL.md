---
name: ai-reindex
description: Rebuild the Obsidian wikilink indexes across the whole engineering/ tree so every note is connected in the graph. Use to reindex, "rebuild the engineering index", "recreate the obsidian links/graph", or fix orphaned notes after moving/deleting files. Deterministically regenerates the root, per-project, and per-feature index.md files.
---

You rebuild the three tiers of `index.md` for the entire `engineering/` vault so
the `ai-*` documents form a fully connected Obsidian graph. This is the
authoritative, deterministic rebuild — it repairs any drift left by the
individual skills' incremental updates.

<critical>This skill NEVER edits the body of existing documents. It only creates/replaces `index.md` files. Regenerating an index is delete-then-recreate, so it must be idempotent — running twice yields identical output.</critical>

## Conventions (read first)

Read `references/index-conventions.md` in full and follow it exactly. It defines
the wikilink format, the three index tiers, their exact markdown, the ordering
rules, and the rebuild recipe. Everything below just sequences those rules over
the whole tree.

## 1. Verify the Obsidian MCP is reachable

Call `obsidian_list_files_in_vault` (or `obsidian_get_recent_changes`). If it
fails, stop and tell the user to set up the Obsidian integration (run `ai-setup`).
Everything else depends on this working.

## 2. Walk the tree and rebuild bottom-up

Rebuild leaves before their parents so each parent links to indexes that already exist.

1. `obsidian_list_files_in_dir("engineering")` → each subdirectory is a `<project>`.
2. For each `<project>`:
   a. `obsidian_list_files_in_dir("engineering/<project>/workplans")` (skip if absent)
      → for each `<feature>` folder, **rebuild** its
      `engineering/<project>/workplans/<feature>/index.md` (feature tier).
   b. **Rebuild** `engineering/<project>/index.md` (project tier): list the
      feature folders under `workplans/`, plus the `.md` files under
      `code-reviews/`, `codebase-reviews/`, and `pull-requests/`. Omit empty sections.
3. **Rebuild** `engineering/index.md` (root tier): one bullet per project.

Use the "Rebuild recipe for one index" from the conventions file for every
`index.md` (list → build body → delete-if-present → create).

## 3. Report

Print a short summary: how many projects, features, and index files were rebuilt,
and flag anything skipped (e.g. a project with no `workplans/`). If you noticed
loose files that don't fit the layout, mention them — don't try to move them.

## Notes

- Recurse only into the folders the layout defines. Don't descend into a feature
  folder looking for sub-features — features are flat.
- If `engineering/` doesn't exist, tell the user to run `ai-setup` first.
- Timestamped review/PR filenames are used verbatim as both link target and alias.
