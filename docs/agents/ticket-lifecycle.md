# Ticket lifecycle

An implementation ticket is in one of the states below. `docs/agents/issue-tracker.md` maps each state to the tracker's storage and gives the commands. When a step says "move the ticket to `<state>`", apply that mapping.

## States

- `ready-for-agent`: fully specified, waiting to be claimed.
- `claimed`: one agent holds the ticket and works it.
- `needs-human`: the holder stopped because only a person can clear the obstacle.
- `resolved`: done. Terminal.
- `wontfix`: a person dropped the work. Terminal.

## Transitions

| From | To | Actor | Condition |
| --- | --- | --- | --- |
| `ready-for-agent` | `claimed` | agent | Every blocker is `resolved` and no one else holds the ticket. Claim before the first change. |
| `claimed` | `resolved` | the holder | Every acceptance criterion is ticked, every required check passes, the review has no unresolved Standards or Spec findings, and the change is committed. Record the commit SHA. |
| `claimed` | `needs-human` | the holder | A person must act. Record the failure comment, release the claim, and keep the branch. |
| `needs-human` | `ready-for-agent` | person | The obstacle is cleared. |
| `claimed` | `ready-for-agent` | person | The holder ended without moving the ticket. Release the claim and keep the branch. |
| `ready-for-agent`, `needs-human` | `wontfix` | person | Every dependent is `wontfix` first, or its blocking edge to this ticket is removed on purpose. |

Every move starts from the exact state in the From column. When the ticket is in any other state, report it and leave it unchanged. Only a person sets `wontfix` or clears `needs-human`.

## Comments

The failure comment records only what went wrong, one fact per line:

```markdown
- needs-human: <the obstacle in one sentence>
- action: <what a person must do>
- review: <file:line> <unresolved finding>
```

Write one `review:` line per unresolved finding, and omit the line when there are none. A `resolved` ticket gets no comment; the commit records the work.
