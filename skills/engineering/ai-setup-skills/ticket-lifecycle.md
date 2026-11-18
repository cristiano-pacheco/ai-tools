# Ticket lifecycle

An implementation ticket moves through the states below. The names are canonical roles; `docs/agents/issue-tracker.md` maps each to the tracker's storage and gives the commands. When a skill says "move the ticket to `<state>`", apply that mapping.

## States

- `ready-for-agent`: fully specified, waiting for an implementer. Triage and `ai-to-tickets` put tickets here.
- `in-progress`: claimed by one implementer, who works it in a worktree on the ticket branch.
- `ready-for-agent-review`: committed on the ticket branch, waiting for a reviewer.
- `fix-code-review`: the reviewer recorded findings; waiting for an implementer to fix them.
- `needs-human`: only a person can clear the obstacle.
- `resolved`: reviewed with no findings and merged into the base branch. Terminal.
- `cancelled`: accepted work that a person dropped. Terminal.

## Transitions

| From | To | Actor | Condition |
| --- | --- | --- | --- |
| `ready-for-agent` | `in-progress` | implementer | Claim. Every blocker is `resolved`. |
| `fix-code-review` | `in-progress` | implementer | Claim to fix the recorded findings. |
| `in-progress` | `ready-for-agent-review` | implementer | Every acceptance criterion is ticked, every required check passes, and the change is committed on the ticket branch. Release the claim. |
| `ready-for-agent-review` | `resolved` | reviewer | The review reports no Standards or Spec findings, and the reviewer has merged the ticket branch into the base branch. |
| `ready-for-agent-review` | `fix-code-review` | reviewer | The review has findings and the review round is below 2. Record the findings comment, add 1 to the round, and release the claim. |
| `in-progress`, `ready-for-agent-review`, `fix-code-review` | `needs-human` | the agent holding the ticket | A person must act, or the review found problems in round 2. Record the failure comment and release the claim. |
| `needs-human` | `ready-for-agent` | person | The obstacle is cleared. |
| `in-progress` | `ready-for-agent` | dispatcher | The implementer ended without moving the ticket. Release the claim and keep the worktree. |
| any non-terminal state | `cancelled` | person | Every dependent is cancelled first, or its edge to this ticket is removed on purpose. |

A ticket is claimable only from `ready-for-agent` or `fix-code-review`. Every other move starts from the exact state in the From column; when the ticket is in any other state, report it and leave it unchanged. The reviewer is a different agent from the implementer.

## Comments

The reviewer records findings, one per line:

```markdown
- review round <n>: <file:line> <finding>
```

The failure comment records only what went wrong, one fact per line:

```markdown
- needs-human: <the obstacle in one sentence>
- action: <what a person must do>
- review: <file:line> <unresolved finding>
```

Write one `review:` line per unresolved finding, and omit the line when there are none. A `resolved` ticket gets no comment; the merge commit records the work.
