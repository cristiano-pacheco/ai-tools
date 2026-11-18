# Issue tracker: Beads

Implementation tickets follow `docs/agents/ticket-lifecycle.md`. Read it whenever you fetch a ticket to work on it: claim the ticket before any other step.

Issues and specs live in a Beads workspace that can hold several projects. Use the `bd` CLI for all operations.

## Preflight

Run this once per session, before the first tracker call:

```sh
command -v bd >/dev/null || { echo "bd not installed"; exit 1; }
bd where
bd config get status.custom
```

If `bd` is missing, stop the tracker operation and tell the user to install Beads. `bd where` prints the workspace: the `BEADS_DIR` path when that variable is set, even outside this repo, otherwise the repo's `.beads/` directory. `BEADS_DIR` is usually exported from the shell profile, so `bd` reaches the shared workspace from any directory. It only locates the database and never names a project; see **Project** below. If `bd where` errors, stop and tell the user to check `BEADS_DIR` or run `bd init`. If `status.custom` lacks `needs_human`, stop and tell the user to rerun `/ai-setup-skills`.

## Model

- **Project**: every issue, specs and epics included, carries a `project` metadata key. Its value is the basename of `git rev-parse --show-toplevel` run from the current directory, or `basename "$PWD"` when the current directory is not in a git repo. This repo's is `<project-name>`. Never derive it from the Beads workspace: the `bd where` path, `BEADS_DIR`, and the ID prefix all name the shared workspace, not the project. A spec whose work touches several repos still gets `<project-name>`.
- **Issue**: any Beads issue, with its `project`.
- **Spec**: an epic (`-t epic`) labelled `spec`, with the spec as its body. A spec is never a plain issue. `/ai-to-spec` creates only the epic; `/ai-to-tickets` later creates its tickets as children of that epic. Until it has a child, the epic is missing from `bd epic status` and from views built on it, such as beads-ui's Epics tab; it still shows as an epic in `bd list` and `bd show`.
- **Ticket**: a child issue of a spec, map, or other parent issue. Children get IDs `<parent-id>.1`, `<parent-id>.2`, and so on, in creation order.
- **IDs** look like `<prefix>-<hash>`. Beads has no issue URLs; refer to an issue by its ID.

Write every multi-line body to stdin with a quoted heredoc (`<<'EOF'`) so the shell leaves backticks and `$` alone. `--silent` makes `bd create` print only the new ID; capture it for later edges. List commands return 50 rows unless given `-n 0`.

## Conventions

- **Create an issue**: `bd create "<title>" -l <labels> --metadata '{"project":"<project-name>"}' --silent --body-file - <<'EOF'`. Never omit `--metadata`.
- **Create a spec**: `bd create "<title>" -t epic -l spec,<labels> --metadata '{"project":"<project-name>"}' --silent --body-file - <<'EOF'`. Never omit `-t epic`; without it `bd` creates a `task`.
- **Verify a created issue**: `bd show <id> --json | jq '.[0] | {issue_type, labels, project: .metadata.project}'`. A spec must show `issue_type` `epic`, a `spec` label, and project `<project-name>`; any issue must show its project. Repair a mismatch with `bd update <id> --type epic` or `--set-metadata project=<project-name>`, then verify again.
- **Create a child issue**: add `--parent <parent-id> --no-inherit-labels`. Without `--no-inherit-labels` the child copies the parent's labels. Children do not inherit `project`; pass `--metadata` on each one.
- **Make an existing issue a child**: `bd update <child-id> --parent <parent-id>`
- **Blocking**: native dependencies. Pass `--deps blocked-by:<id>,blocked-by:<id>` to `bd create`, or add an edge later with `bd dep add <blocked-id> <blocker-id>`. Remove one with `bd dep remove <blocked-id> <blocker-id>`. `bd` rejects edges that would form a cycle. Blockers may belong to other projects. A ticket is unblocked when every blocker is closed.
- **Count open blockers**: `bd show <id> --json | jq '[.[0].dependencies[] | select(.dependency_type=="blocks" and .status!="closed")] | length'`. 0 means startable.
- **List dependents**: `bd dep list <id> --direction=up --json`
- **Change an issue's project**: `bd update <id> --set-metadata project=<name>`
- **Read an issue**: `bd show <id>` prints the body, labels, metadata, parent, blockers, and comments. For JSON, use `bd show <id> --json --include-comments`. The reporter is `created_by`. `bd comments <id> --json` gives each comment's `author` and `created_at`.
- **List issues**: `bd list --metadata-field project=<project-name> --status open --sort created -r -n 0 --json --brief | jq '[.[] | {id, title, status, labels, assignee, parent, created_by, created_at}]'`, oldest first. Filter with `--label <label>` (all must match), `--label-any`, `--no-labels` for never-triaged issues, `--parent <id>`, `-t <type>`, or `--status` (comma-separated for several; `--all` for every status). `bd show` the hits that need body or comments.
- **List specs**: `bd list -t epic --label spec --metadata-field project=<project-name> -n 0 --json --brief`
- **Comment on an issue**: `bd comment <id> --stdin <<'EOF'`
- **Apply / remove labels**: `bd update <id> --add-label <label>` / `--remove-label <label>`. Beads creates a label on first use, so a misspelled label silently becomes a new one; `bd label list-all` shows every label in use.
- **Update a body**: `bd update <id> --body-file -` replaces the whole body. Run `bd show <id>` immediately before, then change only the intended part. Ticking an acceptance criterion is a body update that turns `- [ ]` into `- [x]`.
- **Close**: post the explanation with `bd comment <id> --stdin`, then `bd close <id> --reason "<one-line reason>"`. On an already-closed issue, `bd close` keeps the old reason and still exits 0, so check the status first.
- **Reopen**: `bd reopen <id>`
- **Delete**: `bd delete <id>` removes the issue and every dependency edge on it. Use it only for an issue that should never have existed; close everything else.

## Pull requests as a triage surface

**PRs as a request surface: no.** Beads has no pull requests, so `/triage` covers issues only.

## When a skill says "publish to the issue tracker"

Every create passes `--metadata '{"project":"<project-name>"}'` and is followed by **Verify a created issue**.

- **A spec** (`/ai-to-spec`): run **Create a spec**. The result is one epic with no children; create no tickets here.
- **A ticket graph** (`/ai-to-tickets`): each ticket's project is `<project-name>` unless the conversation already named another project for it. Show that project in the breakdown; ask about it only when the conversation has not settled it. Create each ticket with **Create a child issue** under the spec epic, or under the parent issue the user named, in dependency order, blockers first, each with its `project` and `blocked-by` edges. When the source spec is not an epic, stop and tell the user rather than attaching tickets to it.
- **Anything else**: run **Create an issue**.

## When a skill says "fetch the relevant ticket"

Read it as in **Read an issue** above. To work the ticket, claim it next, before any other step: **Check a named ticket**, then **Claim**, then confirm with `bd show <id> --json | jq '.[0] | {status, assignee}'` that the status is `in_progress` and the assignee is you. When the claim fails, stop and report; another agent holds the ticket.

## When a skill says "resolve a ticket" or "close work"

Run `bd close <id> --reason "resolved: <commit-sha>"`, then `bd show <id>` and confirm the status is `closed` with that reason. Closing unblocks the ticket's dependents.

## Ticket lifecycle

`docs/agents/ticket-lifecycle.md` defines the states and who moves a ticket between them. Beads stores them as:

| State | Storage |
| --- | --- |
| `ready-for-agent` | status `open`, label `ready-for-agent`, no assignee |
| `claimed` | status `in_progress`, assignee is the holder |
| `needs-human` | status `needs_human`, no assignee |
| `resolved` | closed, reason `resolved: <commit-sha>` |
| `wontfix` | closed, reason `wontfix: <why>`, label `wontfix` |

The custom `needs_human` status keeps dependents blocked. Every `--if-status` guard writes nothing on a mismatch and exits 13; treat 13 as "the ticket moved" and re-read it.

- **Check a named ticket**: `bd show <id> --json | jq '.[0] | {status, assignee, labels, project: .metadata.project, open_blockers: [.dependencies[] | select(.dependency_type=="blocks" and .status!="closed") | .id]}'`. It is claimable when the status is `open`, the labels include `ready-for-agent`, the assignee is `null`, the project is `<project-name>`, and `open_blockers` is `[]`.
- **Next ticket**: `bd ready -l ready-for-agent --metadata-field project=<project-name> --exclude-type epic --unassigned --sort oldest --json --brief`, plus `--parent <spec-id>` for one spec. It returns unassigned `open` tickets with no open blocker; the first is next.
- **Claim**: `bd update <id> --claim`. It sets the assignee to you and the status to `in_progress`, and fails when someone else holds the ticket.
- **Resolve**: `bd close <id> --reason "resolved: <commit-sha>"`, then `bd show <id>` to confirm status `closed` with that reason. Closing unblocks the dependents.
- **Needs a person**: `bd comment <id> --stdin` with the failure comment, then `bd update <id> --if-status in_progress --status needs_human --assignee ''`.
- **Person clears**: `bd update <id> --if-status needs_human --status open`
- **Release an abandoned claim**: `bd unclaim <id>`. It works only on `in_progress`.
- **Wontfix**: `bd dep list <id> --direction=up --json` lists the dependents; each must be `wontfix` or have its edge removed with `bd dep remove <dependent-id> <id>`, because closing would otherwise unblock them. Then `bd close <id> --force --reason "wontfix: <why>" && bd update <id> --add-label wontfix`. `--force` is needed because `bd close` refuses an issue with open blockers; use it only for wontfix.

## Wayfinding operations

Used by `/wayfinder`. The **map** is one epic, and its **child** issues are the tickets. Maps and their tickets carry only `wayfinder:` labels, plus the `project` metadata. They skip the ticket lifecycle; a ticket is open until resolved, and claimed by its assignee.

- **Map**: create an issue with `-t epic -l wayfinder:map` and the map body: Destination, Notes, Decisions so far, Not yet specified, Out of scope.
- **Child ticket**: create a child issue of `<map-id>` with label `wayfinder:<type>`, where `<type>` is `research`, `prototype`, `grilling`, or `task`.
- **Blocking**: see **Blocking** under Conventions. Wire edges in a second pass, after every ticket has an ID, and keep every blocker inside the map.
- **Frontier query**: `bd ready --parent <map-id> --exclude-type epic --unassigned --sort oldest --json --brief`. It drops tickets with an open blocker or an assignee. The first result wins; check a named ticket with **Count open blockers** and its `assignee`.
- **Claim**: `bd update <id> --claim`, the session's first write. It sets the assignee to you and fails when someone else holds the ticket.
- **Map update**: see **Update a body** under Conventions.
- **Resolve**: `bd comment <id> --stdin` with the answer, `bd close <id> --reason "<gist>"`, then append `- **<title>** (<id>): <gist>` to the map's Decisions so far. Link assets, such as a research branch, in a comment.
- **Out of scope**: `bd close <id> --reason "out of scope: <why>"`, then append `- **<title>** (<id>): <gist>, <why>` to the map's Out of scope, not Decisions so far.
- **Invalidated ticket**: update its body, close it with the reason, or delete it if it never should have existed.
