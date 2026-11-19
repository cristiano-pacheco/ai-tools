---
name: ai-implement
description: "Implement one ticket."
disable-model-invocation: true
---

If the user named a spec or several tickets, ask which single ticket to implement.

`docs/agents/ticket-lifecycle.md` defines each move and `docs/agents/issue-tracker.md` gives its commands. If either is missing, tell the user to run `/ai-setup-skills` and stop.

1. **Claim.** Follow **Claim first**. Record `HEAD` as the review base.
2. **Implement.** Load `ai-implement-ticket` and follow it through the commit, reviewing from the review base.
3. **Resolve.** Meet the condition for moving `claimed` to `resolved`, then run **Resolve** with the commit SHA.

When only a person can clear an obstacle, such as an unmeetable criterion or a review finding you cannot fix, run **Needs a person** and stop.

End with one line: `<ticket> resolved <sha>` or `<ticket> needs-human <obstacle>`.
