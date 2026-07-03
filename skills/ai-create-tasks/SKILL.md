---
name: ai-create-tasks
description: Break a PRD and tech spec into an implementation task list plus per-task files, saved to Obsidian. Use when the user wants tasks, a task breakdown, or work plan for a feature that has a PRD and tech spec ("split this into tasks", "what are the steps to build X"). Reads both from the vault.
---

You are specialized in **software development project management**. Your task is to create a **detailed list of tasks** from a PRD and a tech spec for a specific feature.

This is the third step of a spec-driven workflow. The task files are read later by `ai-execute-task`, so they must be saved to the vault.

<critical>BEFORE GENERATING ANY FILE, SHOW THE HIGH-LEVEL TASK LIST TO THE USER FOR APPROVAL.</critical>
<critical>DO NOT IMPLEMENT ANYTHING — the focus of this step is the task list and task detailing.</critical>
<critical>EACH TASK MUST BE A FUNCTIONAL, INCREMENTAL DELIVERABLE.</critical>
<critical>EACH TASK MUST HAVE A SET OF TESTS THAT GUARANTEE ITS FUNCTIONALITY AND BUSINESS OBJECTIVE.</critical>

## Templates and inputs

- Task list structure: `references/tasks-template.md` (follow it strictly).
- Individual task structure: `references/task-template.md` (follow it strictly).
- Required inputs, read from the vault: `engineering/<project>/workplans/<feature>/prd.md` and `engineering/<project>/workplans/<feature>/tech-spec.md`.

## Output to Obsidian

All output goes to the user's Obsidian vault via the `mcp__mcp-obsidian__*` tools, grouped by project. Nothing is written to local disk.

### Resolve the project base path

1. Run `git rev-parse --show-toplevel`; the basename is the project name.
2. If not a git repo, propose a name from `basename "$PWD"` (kebab-cased) and **confirm with the user**.
3. Base path: `engineering/<project>`.

### Resolve the feature and read inputs

**If the user gave you a feature identifier** (the `<feature>` slug, e.g. `river-job-index-bloat`) in their request, use it directly as `<feature>` and confirm the folder exists with `obsidian_list_files_in_dir`. Otherwise, list `engineering/<project>/workplans` with `obsidian_list_files_in_dir` to find the feature folder; if ambiguous or missing, ask the user. Read the PRD and tech spec with `obsidian_get_file_contents`. If either is missing, stop and tell the user to run `ai-create-prd` / `ai-create-techspec` first.

When you finish, echo the `Feature ID: <feature>` and the next step (`ai-execute-task` for `<feature>`) so the chain can continue in a fresh session.

### Write the files (no whole-file overwrite tool)

All task files live in the feature's folder under `workplans/`, alongside the PRD and tech spec. For each file you write (`engineering/<project>/workplans/<feature>/tasks.md` and each `engineering/<project>/workplans/<feature>/NN-task.md`): check existence with `obsidian_get_file_contents`, delete with `obsidian_delete_file` (pass `confirm: true`) if present, then create with `obsidian_append_content` (it creates missing parent folders). Number individual task files with a zero-padded prefix and a hyphen: `01-task.md`, `02-task.md`, …

### Maintain the index (keep the graph connected)

After saving, wire every file you wrote into the Obsidian graph with append-if-missing. Wikilinks use vault-root-relative paths + alias.

1. **Feature index** — `engineering/<project>/workplans/<feature>/index.md`: read it (if missing, create it with `# <feature>` and a `↑ [[engineering/<project>/index|<project>]]` back-link); for each file you wrote whose wikilink isn't present, `obsidian_append_content` a bullet under `## Documents` — `- [[engineering/<project>/workplans/<feature>/tasks|Tasks]]` and `- [[engineering/<project>/workplans/<feature>/NN-task|Task NN]]` for each task file.
2. **Project index** — `engineering/<project>/index.md`: ensure a bullet `- [[engineering/<project>/workplans/<feature>/index|<feature>]]` exists under `## Workplans` (create the file with `# <project>` + `↑ [[engineering/index|Engineering]]` if missing).
3. **Root index** — `engineering/index.md`: ensure a bullet `- [[engineering/<project>/index|<project>]]` exists under `## Projects` (create it if missing).

Never duplicate an existing link. `ai-reindex` rebuilds all indexes deterministically; this step just keeps the graph live.

## Process

### 1. Analyze the PRD and tech spec

Extract requirements and technical decisions; identify the main components.

### 2. Propose the task structure (get approval first)

Organize sequencing, with dependencies before dependents (backend before frontend; both before E2E). Each main task must be an independently completable, functional deliverable with its own unit and integration tests. **Show this high-level list to the user and wait for approval before writing any file.**

### 3. Generate the files

- `tasks.md` — the summary, following `references/tasks-template.md`. Fill its related-links blockquote (under the H1) with `[[engineering/<project>/workplans/<feature>/tech-spec|tech-spec]]` and `[[engineering/<project>/workplans/<feature>/prd|prd]]`.
- One `NN-task.md` per main task, following `references/task-template.md`, detailing subtasks, success criteria, and the unit/integration tests. Fill its related-links blockquote with links to `tasks`, `tech-spec`, and `prd` in the same feature folder.

## Guidelines

- Assume the reader is a **junior developer** — be as clear as possible.
- **Avoid more than 10 main tasks** (group logically).
- Use X.0 for main tasks, X.Y for subtasks.
- Clearly indicate dependencies and mark tasks that can run in parallel.
- Per-task files should point readers to the PRD and tech spec in the same feature folder rather than restating their full content.

After generating all files, present the results and the vault paths, and wait for confirmation before any implementation.

<critical>DO NOT IMPLEMENT ANYTHING IN THIS STEP.</critical>
