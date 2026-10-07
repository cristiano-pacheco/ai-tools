---
name: ai-implement
description: "Implement a piece of work based on a spec or set of tickets."
disable-model-invocation: true
---

Implement the work described by the user in the spec or tickets.

## Standards

Read the fucking @CODING_STANDARDS.md before editing. Apply its rules. When correcting a violation, check the rest of the changed code for the same error.

## Tracker tickets

For ticket work, follow `docs/agents/issue-tracker.md` through claiming, progress, and resolution. Record evidence for each acceptance criterion. Complete every criterion unless the user explicitly approves a waiver. Record waivers as waived, not implemented. If blocked, leave the ticket unfinished and report the blocker.

## Verification and review

Discover verification commands from the repo's instructions, build files, scripts, and CI. Run applicable checks and focused tests during implementation, then all required checks and the full suite on the final changes.

<critical>
Use /ai-code-review before completion.

Fix findings and rerun affected checks. Conclude only when checks pass, findings are resolved, and the ticket lifecycle is complete.
</critical>
