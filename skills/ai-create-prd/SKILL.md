---
name: ai-create-prd
description: Create a Product Requirements Document (PRD) for a feature and save it to Obsidian. Use when the user wants to write or draft a PRD, product spec, or requirements — including phrasings like "spec out this feature" or "write requirements for X". Asks clarifying questions before writing.
---

You are an expert at creating PRDs, focused on producing **clear, actionable requirement documents** for product and development teams.

This skill is the first step of a spec-driven workflow. The PRD it produces is read later by `ai-create-techspec`, `ai-create-tasks`, and `ai-execute-task` — all of which read it back from Obsidian. So the PRD must be saved to the vault, not to local disk.

<critical>DO NOT GENERATE THE PRD WITHOUT FIRST ASKING CLARIFYING QUESTIONS.</critical>
<critical>UNDER NO CIRCUMSTANCES DEVIATE FROM THE PRD TEMPLATE.</critical>

## Objectives

1. Capture **complete, clear, and testable requirements** focused on users and business outcomes.
2. Follow the **structured workflow** before writing any PRD.
3. Generate the PRD from the bundled template and save it to the correct vault location.

## Template

The PRD structure is defined in `references/prd-template.md`. Read it and follow it exactly — focus on **WHAT and WHY, not HOW** (implementation belongs in the tech spec).

## Output to Obsidian

All output goes to the user's Obsidian vault via the `mcp__mcp-obsidian__*` tools, grouped by project. Nothing is written to local disk.

### Resolve the project base path

1. Run `git rev-parse --show-toplevel`; the basename of that path is the project name.
2. If the current directory is not a git repo (the command fails), propose a project name from `basename "$PWD"` (kebab-cased) and **confirm it with the user before writing**.
3. The base path in the vault is `engineering/<project>`.

### Resolve the feature folder

The PRD lives at `engineering/<project>/<feature>/workplan/prd.md`, where `<feature>` is a kebab-case slug describing the feature (e.g. `queue-routing`). `workplan/` is the per-feature folder that holds the full set of working documents (PRD, tech spec, tasks, and the artifacts produced while building). Derive the slug from the feature name; if a folder for this feature may already exist, list `engineering/<project>` with `obsidian_list_files_in_dir` and reuse the matching folder.

### Write the file (there is no whole-file overwrite tool)

The Obsidian MCP only exposes append / patch / delete. To write `engineering/<project>/<feature>/workplan/prd.md`:

1. Check if it exists with `obsidian_get_file_contents`.
2. If it exists, delete it with `obsidian_delete_file` (pass `confirm: true`) — regenerating a PRD replaces it; appending would duplicate content.
3. Create it with `obsidian_append_content`. This creates any missing parent folders, so you don't pre-create directories.

## Workflow

### 1. Clarify (mandatory)

Use your ask-user-question tool to understand:

- The problem to be solved
- Core functionality
- Constraints
- What is **out of scope**

### 2. Plan (mandatory)

Outline a section-by-section approach, note areas needing research (use web search for business rules when relevant), and state assumptions and dependencies.

### 3. Write the PRD (mandatory)

- Follow `references/prd-template.md`.
- Focus on WHAT and WHY, not HOW.
- Include **numbered functional requirements**.
- Keep the document under ~2,000 words.

### 4. Save (mandatory)

Write to `engineering/<project>/<feature>/workplan/prd.md` using the write recipe above.

### 5. Report

Give the final vault path and a **very brief** summary of the PRD.

## Quality checklist

- [ ] Clarifying questions asked and answered
- [ ] PRD follows the template
- [ ] Numbered functional requirements included
- [ ] Saved to `engineering/<project>/<feature>/workplan/prd.md`
- [ ] Final vault path reported

<critical>DO NOT GENERATE THE PRD WITHOUT FIRST ASKING CLARIFYING QUESTIONS.</critical>
<critical>UNDER NO CIRCUMSTANCES DEVIATE FROM THE PRD TEMPLATE.</critical>
