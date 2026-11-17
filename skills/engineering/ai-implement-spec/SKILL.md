---
name: ai-implement-spec
description: "Implement every ticket of a spec in parallel worktrees, merged into one integration branch."
disable-model-invocation: true
---

You are the **orchestrator**. Work the **frontier** of one spec until it is empty: dispatch one **implementer** per ticket, each in its own worktree, and merge their commits into the **integration branch**. You never implement a ticket yourself. Use the vocabulary in `GLOSSARY.md` when it exists.

The arguments name the feature (its slug or its `spec.md` path) and may give a number: the maximum number of implementers running at once. The default is 3.

<critical>
Run one orchestrator per spec. Two orchestrators on the same spec dispatch the same tickets, because ticket claims are plain file edits.
</critical>

## 1. Check the inputs

1. Read `docs/agents/issue-tracker.md`. It must be the Obsidian adapter (`# Issue tracker: Obsidian`). For any other tracker, report that `ai-implement-spec` supports only Obsidian and stop.
2. Resolve the feature directory as the adapter defines it. Read `spec.md` and the frontmatter of every file in `issues/`.
3. Validate the ticket graph: every ticket has `status` and `blocked_by` frontmatter, every `blocked_by` entry names an existing ticket number, and the graph has no cycle. Tickets that use the old `**Blocked by:**` line fail this check. On any failure, list every problem and stop; these tickets are implemented one at a time with `/ai-implement`.

## 2. Prepare the integration branch

The integration branch is named after the feature slug. The worktree root is `<repo-root>/../<repo-name>.worktrees/`. Ticket `NN` uses branch `<feature>-<NN>` and worktree `<worktree root>/<feature>-<NN>`.

1. Require a clean working tree in the main checkout. If it is dirty, report it and stop.
2. Check out the integration branch, creating it from the current `HEAD` if it does not exist.
3. Recover from an interrupted run:
   - A `claimed` ticket was interrupted. Remove its worktree and branch, then set its status back to `ready-for-agent`.
   - A `resolved` ticket whose branch still exists and is not merged into the integration branch is waiting for its merge. Merge it as in step 4.
   - A `needs-human` ticket keeps its worktree for inspection. Leave it alone.

## 3. Dispatch the frontier

A ticket is **merged** when it is `resolved` and its commit is in the integration branch. The frontier is every `ready-for-agent` ticket whose `blocked_by` tickets are all merged, in number order. The orchestrator ignores `ready-for-human` and `wontfix` tickets.

While implementers are below the limit and the frontier is not empty, dispatch the next frontier ticket:

1. Create its worktree on a new ticket branch from the integration branch tip: `git worktree add -b <feature>-<NN> <worktree> <integration branch>`.
2. Start an implementer in the background, with the worktree as its working directory. Use the harness's subagent mechanism. If the harness has none, run a headless session of the same CLI from the worktree, such as `claude -p`, `pi -p`, or `codex exec`. Pass only this prompt:

   ```text
   Use the ai-implement-ticket skill for ticket <absolute ticket path>.
   Work only inside <absolute worktree path>.
   ```

Keep the per-ticket state in your context to the implementer's one-line report. Read the ticket file or git when you need more.

## 4. Merge each report

Handle each report as it arrives, then return to step 3. The ticket file is the source of truth: when the report and the file disagree, or the implementer ended without a report, mark the ticket `needs-human` with the obstacle `implementer ended without a valid report`.

**`<NN> resolved <branch> <commit>`.** In the main checkout, run `git merge --no-ff --no-edit <branch>` into the integration branch.

- On success, remove the ticket's worktree and branch.
- On conflict, run `git merge --abort`. Dispatch an implementer in the ticket's worktree with this prompt: `Merge <integration branch> into <branch> inside <worktree>. Resolve the conflicts so both sides keep their intent, run the repo's required checks, commit the merge, and reply with one line: "merged <commit>" or "needs-human <obstacle>".` When it reports `merged`, retry the merge once. If the conflict persists or the implementer reports `needs-human`, abort the merge and mark the ticket `needs-human`, with the obstacle `merge conflict with the integration branch` and the action `resolve the conflict in <worktree>`.

**`<NN> needs-human <obstacle>`.** Keep the worktree and branch. The ticket's dependents stay off the frontier.

## 5. Verify the integration branch

The run is complete when no implementer is running and the frontier is empty. If no ticket was merged in this run, skip to step 6.

1. Run every required check and the full suite on the integration branch.
2. Run /ai-code-review with the integration branch's merge-base against the branch it was created from as the fixed point and `spec.md` as the spec.
3. If checks fail or the review has findings, dispatch one implementer in the main checkout. Pass it the failing checks and the findings, as `file:line` plus the finding, and ask it to fix them, rerun the checks, write one Conventional Commit, and reply with one line: `fixed <commit>` or `needs-human <obstacle>`. Then rerun the checks and the review once.

## 6. Report

Report:

- the integration branch, and that nothing was pushed;
- each ticket that is not merged, with its status, obstacle, and worktree path;
- the failing checks and review findings that remain after step 5.

Close nothing else. A person reviews the integration branch and opens the PR.
