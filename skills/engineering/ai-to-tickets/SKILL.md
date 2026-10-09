---
name: ai-to-tickets
description: Break a plan, spec, or the current conversation into small, focused tickets, each declaring its blocking edges, published to the configured tracker (edges as text in one file per ticket locally, or native blocking links on a real tracker).
disable-model-invocation: true
---

# To Tickets

Break a plan, spec, or conversation into small, focused **tickets**, each covering one concrete task with minimal context and declaring the tickets that **block** it.

The issue tracker and triage label vocabulary should have been provided to you. If not, tell the user to run `/ai-setup-skills`.

<critical>
Before creating or editing any Markdown file, load the /unslop skill and follow its guidelines for writing and reviewing text.
</critical>

## Process

### 1. Gather context

Work from whatever is already in the conversation context. If the user passes a reference (a spec path, an issue number or URL) as an argument, fetch it and read its full body and comments.

### 2. Explore the codebase (optional)

If you have not already explored the codebase, do so to understand the current state of the code. Ticket titles and descriptions should use the project's domain glossary vocabulary, and respect ADRs in the area you're touching.

Look for opportunities to prefactor the code to make the implementation easier. "Make the change easy, then make the easy change."

### 3. Draft small tasks

Break the work into small, focused **tickets**.

- Each ticket covers one concrete change with clear acceptance criteria, including at least one type of test.
- For HTTP handlers and the HTTP transport layer, require end-to-end (E2E) tests through the HTTP interface, never unit tests. This rule takes precedence over the dependency-based rules below.
- For code without dependencies on other instances, require only unit tests.
- For code with dependencies on other instances, such as a use case or repository, prefer integration tests. These are code dependencies, distinct from ticket blockers.
- Scope each ticket to the context needed for that change; tasks may target a single layer or component.
- Split tickets that combine independently verifiable changes.
- Schedule any required prefactoring before the changes that depend on it.

Give each ticket its **blocking edges**: the other tickets that must complete before it can start. A ticket with no blockers can start immediately.

### 4. Quiz the user

Present the proposed breakdown as a numbered list. For each ticket, show:

- **Title**: short descriptive name
- **Blocked by**: which other tickets (if any) must complete first
- **What it delivers**: the concrete change this ticket makes

Ask the user:

- Does the granularity feel right? (too coarse / too fine)
- Are the blocking edges correct: does each ticket only depend on tickets that genuinely gate it?
- Should any tickets be merged or split further?

Iterate until the user approves the breakdown.

### 5. Publish the tickets to the configured tracker

Publish the approved tickets. **How** depends on the tracker `/ai-setup-skills` configured; the tickets are the same either way, only the shape of the blocking edges changes:

- **Local files** → write one file per ticket under `.scratch/<feature-slug>/issues/<NN>-<slug>.md`, numbered from `01` in dependency order (blockers first). Each file's "Blocked by" lists the numbers/titles it depends on. Use the per-ticket file template below: one ticket per file, never a single combined file.
- **Obsidian** → write one file per ticket under `<vault>/engineering/<project>/workplans/<feature>/issues/<NN>-<slug>.md`, numbered from `01` in dependency order (blockers first). Resolve `<vault>` from `$OBSIDIAN_AI_VAULT` and use absolute filesystem paths, as configured by the issue-tracker adapter. Each file's "Blocked by" lists the numbers/titles it depends on. Use the per-ticket file template below: one ticket per file, never a single combined file.
- **A real issue tracker (GitHub, Linear, …)** → publish one issue per ticket in dependency order (blockers first) so each ticket's blocking edges can reference real identifiers. Use the platform's native blocking / sub-issue relationship where it has one; otherwise set each ticket's "Blocked by" to the blocking issues. Apply the `ready-for-agent` triage label unless instructed otherwise; the tickets are agent-grabbable by construction.

Work the **frontier**: any ticket whose blockers are all done. For a purely linear chain that means top to bottom.

Do NOT close or modify any parent issue.

<local-ticket-template>

# <NN>: <Ticket title>

**What to build:** the concrete change this ticket makes.

**Blocked by:** the numbers/titles of the tickets that gate this one, or "None (can start immediately)".

**Status:** ready-for-agent

- [ ] Acceptance criterion 1
- [ ] Required tests: <unit, integration, or E2E, with the behaviour to verify>

</local-ticket-template>

<issue-template>

## Parent

A reference to the parent issue on the tracker (if the source was an existing issue, otherwise omit this section).

## What to build

The concrete change this ticket makes.

## Acceptance criteria

- [ ] Criterion 1
- [ ] Required tests: <unit, integration, or E2E, with the behaviour to verify>

## Blocked by

- A reference to each blocking ticket, or "None (can start immediately)".

</issue-template>

In either form, avoid specific file paths or code snippets: they go stale fast. Exception: if a prototype produced a snippet that encodes a decision more precisely than prose can (state machine, reducer, schema, type shape), inline it and note briefly that it came from a prototype. Trim to the decision-rich parts, not a working demo, just the important bits.
