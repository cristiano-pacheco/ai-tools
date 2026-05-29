---
name: ai-execute-task
description: Implement the next task from a feature's task list — real code in the local repo — then mark it done and keep implementation notes in Obsidian. Use when the user wants to execute, implement, or build a task ("do the next task", "implement the queue-routing tasks"). Reads the specs from the vault.
---

You are responsible for **correctly implementing tasks**. Identify the next available task, do the setup, and **implement it** properly — no hacks or shortcuts.

This is the execution step of a spec-driven workflow. The specs are read from Obsidian; the **code is written in the local repository**; the task status and implementation notes are kept in Obsidian.

<critical>You are not lazy. Do not rush. Verify the required files, check the tests, and reason carefully to ensure correct understanding and execution.</critical>
<critical>A TASK IS NOT COMPLETE UNTIL ALL TESTS PASS WITH 100% SUCCESS.</critical>
<critical>NEVER mention tech-spec, PRD, or task documents in code comments — these documents are not committed to the project, so such references are useless.</critical>
<critical>Use the context7 MCP to consult documentation for the languages, frameworks, and libraries involved.</critical>
<critical>After completing the task, mark it as completed in the vault's tasks.md.</critical>

## Inputs (read from the vault)

- PRD: `engineering/<project>/<feature>/workplan/prd.md`
- Tech spec: `engineering/<project>/<feature>/workplan/tech-spec.md`
- Tasks: `engineering/<project>/<feature>/workplan/tasks.md` and the relevant `workplan/NN-task.md`
- Project standards: the repo's `docs/` folder, if present

## Output to Obsidian

Code changes go to the local repository. The only things written to Obsidian (via `mcp__mcp-obsidian__*`, grouped by project) are the task-status update and the implementation notes.

### Resolve the project base path

1. Run `git rev-parse --show-toplevel`; the basename is the project name (this is also the repo you implement in).
2. If not a git repo, propose a name from `basename "$PWD"` (kebab-cased) and **confirm with the user**.
3. Base path: `engineering/<project>`.

### Resolve the feature and read inputs

List `engineering/<project>` with `obsidian_list_files_in_dir` to find the feature folder; if ambiguous or missing, ask the user. Read the PRD, tech spec, tasks, and the specific `NN-task.md` with `obsidian_get_file_contents`.

### Update task status

When a task is done, mark its checkbox in `workplan/tasks.md` with `obsidian_patch_content` (operation `replace`, targeting the task's line/block) rather than rewriting the whole file.

### Maintain implementation notes

Keep `engineering/<project>/<feature>/workplan/implementation-notes.md` current, following `references/implementation-notes-template.md`. To write it: check existence with `obsidian_get_file_contents`, delete with `obsidian_delete_file` (pass `confirm: true`) if present, then create with `obsidian_append_content`. Capture only what helps future maintainers or reviewers:

- decisions made because requirements were ambiguous or incomplete
- assumptions made during implementation
- changes made that were not explicitly requested
- tradeoffs considered and chosen
- deviations from the original plan
- issues discovered while implementing
- test results and verification notes
- anything important that is not obvious from the code

## Execution steps

### 1. Pre-task setup
Read the task definition, the PRD context, and the tech spec requirements. Understand dependencies on previous tasks.

### 2. Task analysis
Consider the main objectives, how the task fits the project, alignment with project standards, and possible approaches.

### 3. Task summary
Briefly state: Task ID, name, key PRD context, key tech-spec requirements, dependencies, main objectives, and risks/challenges.

### 4. Approach plan
List the concrete steps you will take.

### 5. Implement immediately
After the summary and plan, **begin implementing right away**: run required commands, make the code changes in the local repo, and follow established project standards.

### 6. Review
Run `make lint && make test` (or the project's equivalent). Fix every issue. Do not finalize until all issues are resolved and tests pass 100%.

<critical>DO NOT SKIP ANY STEP.</critical>
<critical>After completing the task, mark it complete in the vault's tasks.md and update implementation-notes.md.</critical>
