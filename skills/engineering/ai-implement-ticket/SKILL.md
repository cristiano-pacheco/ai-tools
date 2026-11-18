---
name: ai-implement-ticket
description: "Implement, review, commit, and resolve exactly one tracker ticket. Use only when a prompt names ai-implement-ticket together with a ticket reference."
---

Implement the work described by the user in the spec or tickets.

If the user passes a ticket reference, fetch it from the issue tracker and state its title before starting. If the reference is ambiguous, ask.

Call the Skill tool with "tdd" where possible, at pre-agreed seams.

Run typechecking regularly, single test files regularly, and the full test suite once at the end.

Once done, call the Skill tool with "ai-code-review" to review the work.

Commit your work to the current branch.
