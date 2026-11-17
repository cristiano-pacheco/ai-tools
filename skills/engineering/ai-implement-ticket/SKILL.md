---
name: ai-implement-ticket
description: "Implement, review, commit, and resolve exactly one tracker ticket. Use only when a prompt names ai-implement-ticket together with a ticket reference."
---

Implement one ticket in the current working directory and branch, then commit it and resolve it on the tracker.

The issue tracker should have been provided to you in `docs/agents/issue-tracker.md`. If not, report `needs-human: no issue tracker configured` and stop. Every tracker operation below (fetch, claim, tick a criterion, resolve, mark as needing a person) follows that document.

<critical>
Before creating or editing any Markdown file, load the /unslop skill and follow its guidelines for writing and reviewing text.
</critical>

## Steps

1. **Claim.** Fetch the ticket with its comments. Confirm it is claimable, then claim it. Record `HEAD` as the review base. If the ticket is not claimable, report `<ticket> needs-human not claimable: <status>` and stop without editing it.
2. **Read the standards.** Read the fucking @CODING_STANDARDS.md before editing. Apply its rules. When correcting a violation, check the rest of the changed code for the same error.
3. **Implement.** Build exactly what the ticket asks. Account for every acceptance criterion with observable evidence (code, config, tests) and tick each one as soon as it is verified.
4. **Verify.** Discover verification commands from the repo's instructions, build files, scripts, and CI. Run focused tests while implementing, then every required check and the full suite on the final change. Done means every check passes.
5. **Review.** Run /ai-code-review with the review base as the fixed point and the ticket as the spec. Fix every finding and rerun the affected checks. Done means the review reports no unresolved Standards or Spec findings.
6. **Commit.** Stage only the files this ticket changed. Write one Conventional Commit, following the message rules in the `commit` skill, with no `Co-Authored-By` trailer. Commit the staged index with `git commit`.
7. **Resolve.** Resolve the ticket on the tracker and read it back to confirm the saved state.

## Needs human

Stop and mark the ticket as needing a person when only a person can clear the obstacle:

- an acceptance criterion cannot be met as written (a waiver or a ticket change is needed);
- the ticket or spec is ambiguous or contradicts the code;
- a credential, service, or environment the work depends on is unavailable;
- a check or review finding stays unresolved after you have fixed what you can.

Leave unverified criteria unticked and the work uncommitted in the working tree for inspection. Write the comment in the tracker's failure format: the obstacle, the action a person must take, and each unresolved review finding. Record failures only, in as few words as the facts allow.

## Report

End with exactly one line and nothing else:

- `<ticket> resolved <branch> <commit>`
- `<ticket> needs-human <obstacle in a few words>`
