# Issue tracker: Obsidian

Implementation tickets follow `docs/agents/ticket-lifecycle.md`. Read it whenever you fetch a ticket to work on it: claim the ticket before any other step.

## Output to Obsidian

Write specs, tickets, wayfinding maps, and tracker comments directly to the user's Obsidian vault on the local filesystem, without MCP. Group them by project.

**Vault root:** resolve `<vault>` from `$OBSIDIAN_AI_VAULT`. If unset, use `$HOME/Documents/obsidian/obsidian`. Use absolute filesystem paths with the read/write/edit tools. Keep wikilinks vault-root-relative, as in `[[engineering/...]]`.

### Resolve the project base path

1. Use the configured project name `<project-name>` for `<project>`. If not configured, derive it from the basename of `git rev-parse --show-toplevel`.
2. If no project is configured and the command fails, propose a kebab-case name from `basename "$PWD"` and confirm it with the user before writing.
3. Paths below are relative to the feature directory, `<vault>/engineering/<project>/workplans/<feature>/`.

## Preflight

Run this once per session, before the first tracker call:

```sh
vault="${OBSIDIAN_AI_VAULT:-$HOME/Documents/obsidian/obsidian}"
test -d "$vault" || { echo "vault not found: $vault"; exit 1; }
test -d "$vault/engineering/<project>/workplans" || echo "no workplans yet for <project>"
```

If the vault is missing, stop the tracker operation and tell the user to set `OBSIDIAN_AI_VAULT`. A missing `workplans` directory is fine before the first publish; for any other operation, stop and report it.

## Model

- **Spec**: one feature directory, with the spec in `spec.md`.
- **Ticket**: one file at `issues/<NN>-<slug>.md` inside its spec's feature directory.
- **IDs**: a ticket's ID is its two-digit `NN`, unique within the feature. Refer to a ticket outside its feature as `<feature>/<NN>`.
- **Project**: the `<project>` directory. Every ticket of a feature belongs to that project.

Obsidian has no cycle detection, and edits are plain file writes, so read a ticket immediately before every change and read it back after. Claims use a lock directory, described under Ticket lifecycle, because `mkdir` is atomic and a frontmatter edit is not.

## Conventions

- **Create a spec**: write `spec.md` in a new feature directory.
- **Create a ticket**: write `issues/<NN>-<slug>.md` with the frontmatter below. Number tickets from `01` in dependency order, blockers first. Never combine tickets into one file.
- **Blocking**: the `blocked_by` frontmatter list. Every entry names an existing ticket in the same feature. A missing or ambiguous entry blocks execution. A ticket is unblocked when every listed ticket is `resolved`. Before adding an edge, follow the blocker's own `blocked_by` chain and refuse the edge if it leads back to the blocked ticket.
- **Count open blockers**: read each ticket in `blocked_by` and count those whose `status` is not `resolved`. 0 means startable.
- **List dependents**: `grep -l -E '^blocked_by:.*"<NN>"' <feature>/issues/*.md`
- **Read a ticket**: read the complete file, including frontmatter and comments.
- **List tickets**: `grep -H -E '^(status|assignee|labels):' <feature>/issues/*.md`, in file-name order. Filter the output by status or label; read the hits that need body or comments.
- **List specs**: `ls -d <vault>/engineering/<project>/workplans/*/`
- **Comment on a ticket**: append under a `## Comments` heading at the bottom of the file, creating the heading if absent. Start each comment with `### <author> · <ISO-8601 time>`, where `<author>` is `git config user.name` or the agent's role.
- **Apply / remove labels**: edit the `labels` frontmatter list. Use only labels from `triage-labels.md` or ones already in use; check with `grep -h '^labels:' <feature>/issues/*.md`.
- **Change one field**: edit its frontmatter line and preserve the rest of the file.
- **Update a body**: read the file immediately before, then change only the intended part. Ticking an acceptance criterion turns `- [ ]` into `- [x]`.
- **Reopen**: set `status: ready-for-agent` and clear `resolution`.
- **Delete**: remove the file only for a ticket that should never have existed, after **List dependents** shows none. Otherwise use wontfix.

## When a skill says "publish to the issue tracker"

Create the artifact at the path defined in Conventions or Wayfinding operations. Create directories as needed. Use the per-ticket template from `ai-to-tickets` for implementation issues. Preserve existing files and reuse an identical published ticket. Report conflicting content or numbering before writing. Leave the parent spec unchanged.

## When a skill says "fetch the relevant ticket"

Read the complete referenced file, including comments. Resolve an issue number within the identified feature's `issues/` directory; if the feature or ticket is ambiguous, ask for the exact path rather than selecting by similarity or recency.

To work the ticket, claim it next, before any other step: **Check a named ticket**, then **Claim**. When the claim fails, stop and report; another agent holds the ticket.

## When a skill says "resolve a ticket" or "close work"

Use **Resolve** under Ticket lifecycle.

## Implementation ticket frontmatter

Implementation issues (the `issues/NN-slug.md` tickets produced from a spec) start with this frontmatter:

```yaml
---
status: ready-for-agent
type: task
blocked_by: ["01", "03"]
assignee: ""
labels: []
resolution: ""
---
```

- `status` is a state from `ticket-lifecycle.md` or a triage role from `triage-labels.md`.
- `blocked_by` lists the two-digit numbers of tickets in the same feature that must be resolved first, or `[]`.
- `assignee` names the agent holding a `claimed` ticket, and is empty otherwise.
- `labels` lists extra labels, or `[]`.
- `resolution` is set when the ticket reaches a terminal state, and is empty otherwise.

A missing `assignee`, `labels`, or `resolution` line counts as empty. Add the line when you first set it.

## Ticket lifecycle

`docs/agents/ticket-lifecycle.md` defines the states and who moves a ticket between them. Obsidian stores them as:

| State | Storage |
| --- | --- |
| `ready-for-agent` | `status: ready-for-agent`, empty `assignee` |
| `claimed` | `status: claimed`, `assignee` is the holder |
| `needs-human` | `status: needs-human`, empty `assignee` |
| `resolved` | `status: resolved`, `resolution: "resolved: <commit-sha>"` |
| `wontfix` | `status: wontfix`, `resolution: "wontfix: <why>"` |

Each move below is guarded: read the file first and confirm the From state. On a mismatch, write nothing; the ticket moved, so report it. After writing, read the file back and confirm the saved frontmatter.

The claim lock is the directory `issues/.claims/<NN>`. Creating it is the claim; whoever creates it first holds the ticket. Obsidian ignores dot-directories, so the lock stays out of the vault view.

- **Check a named ticket**: read its frontmatter. It is claimable when `status` is `ready-for-agent`, `assignee` is empty, `issues/.claims/<NN>` does not exist, and **Count open blockers** is 0.
- **Next ticket**: scan `issues/*.md` in file-name order. The first claimable ticket is next.
- **Claim**: `mkdir -p <feature>/issues/.claims && mkdir <feature>/issues/.claims/<NN>`. If the second `mkdir` fails, another agent holds the ticket; stop and change nothing. If it succeeds, set `status: claimed` and `assignee: <you>`, where `<you>` is unique to this session, then read the file back and confirm both.
- **Resolve**: set `status: resolved` and `resolution: "resolved: <commit-sha>"`, clear `assignee`, read back the file, then `rmdir <feature>/issues/.claims/<NN>`.
- **Needs a person**: append the failure comment under `## Comments`, then set `status: needs-human` and clear `assignee`. Leave unverified criteria unticked and preserve the worktree. Keep the lock until a person clears the ticket.
- **Person clears**: from `needs-human`, set `status: ready-for-agent`, then `rmdir <feature>/issues/.claims/<NN>`.
- **Release an abandoned claim**: from `claimed`, set `status: ready-for-agent` and clear `assignee`, then `rmdir <feature>/issues/.claims/<NN>`. A lock with no `claimed` ticket behind it is also abandoned; only a person removes it.
- **Wontfix**: **List dependents**; each must be `wontfix` or have this ticket removed from its `blocked_by`. Then set `status: wontfix` and `resolution: "wontfix: <why>"`.

## Wayfinding operations

Used by `/wayfinder`. The **map** is a file with one **child** file per ticket.

- **Map**: `map.md` (the Notes / Decisions-so-far / Fog body).
- **Child ticket**: `issues/NN-<slug>.md`, numbered from `01`, with the question in the body. A `Type:` line records the ticket type (`research`/`prototype`/`grilling`/`task`); a `Status:` line records `claimed`/`resolved`.
- **Blocking**: a `Blocked by: NN, NN` line near the top. A ticket is unblocked when every file it lists is `resolved`.
- **Frontier**: scan `issues/` for files that are open, unblocked, and unclaimed; first by number wins.
- **Resolve**: append the answer under an `## Answer` heading, set `Status: resolved`, then append a context pointer (gist + link) to the map's Decisions-so-far in `map.md`.
