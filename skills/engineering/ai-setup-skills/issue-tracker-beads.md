# Issue tracker: Beads

Implementation tickets follow `docs/agents/ticket-lifecycle.md`. Read it before you work a ticket.

Issues live in a shared Beads workspace that holds several projects. Use the `bd` CLI for every operation.

## Preflight

Run this once per session, before the first tracker call:

```sh
command -v bd >/dev/null || { echo "bd not installed"; exit 1; }
bd where
```

When a check fails, stop the tracker operation and tell the user the fix:

- `bd` is missing: install Beads.
- `bd where` errors: check `BEADS_DIR` or run `bd init`.

A `bd where` path outside this repo is normal. `BEADS_DIR` points at the shared workspace from any directory.

## Model

- **Project**: two metadata keys on every issue. `project` names the project, and `repo` says where its code lives: the absolute path of its local repository, or its GitHub URL `https://github.com/<owner>/<name>` when it has no local clone. Anything created from this repo gets `<project-name>` and `<project-repo>`, even when its work touches other repos. Only `/ai-to-tickets` assigns another project, and only one the conversation named, with its `repo`. The `bd where` path, `BEADS_DIR`, and the workspace's ID prefix name the shared workspace, never a project.
- **Spec**: an epic labelled `spec`, with the spec as its body. `/ai-to-spec` creates the epic alone, and `/ai-to-tickets` adds its tickets as children. A childless epic is absent from `bd epic status` and beads-ui's Epics tab, but `bd list` and `bd show` find it.
- **Ticket**: a child issue of a spec, a wayfinding map, or another parent issue.
- **State**: a ticket's status, plus a state label on `blocked` and `closed`:
  - `open`: ready.
  - `in_progress`: claimed by the assignee.
  - `blocked` + `needs-human`: waits on a person.
  - `closed` + `resolved` or `wontfix`: done. The notes hold the commit SHA or the reason.

  The `bd update` that changes the status also adds or removes the state label. Move a ticket only through the operations under Ticket lifecycle.
- **Kind labels**: `spec` on a spec and `wayfinder:<type>` on wayfinding issues, set at creation.
- **ID**: a top-level issue gets `<project-name>-<slug>`, where the slug is a short kebab-case summary of the title, such as `<project-name>-fix-vulnerabilities`. `bd` numbers a child `<parent-id>.<n>`, and the numbers can skip. Beads has no URLs, so refer to an issue by its ID.

## Conventions

Pass every multi-line body on stdin through a quoted heredoc (`<<'EOF'`), so the shell leaves backticks and `$` alone.

- **Create an issue**:

  ```sh
  bd create "<title>" <placement> --force [-l <kind>] --metadata '{"project":"<project-name>","repo":"<project-repo>"}' --silent --body-file - <<'EOF'
  ```

  `<placement>` is `--id <project-name>-<slug>`. Without `--id`, `bd` names the issue after the workspace. `--force` admits an ID that differs from the workspace prefix, which every ID here does; without it `bd` fails with `prefix mismatch`. `--silent` prints only the new ID; keep it for later edges. When `bd` reports that the ID already exists, pick a more specific slug. Run **Verify a created issue** after every create.
- **Create a spec**: **Create an issue** with `-t epic -l spec`. Without `-t epic`, `bd` creates a `task`.
- **Create a child issue**: **Create an issue** with `<placement>` set to `--parent <parent-id> --no-inherit-labels`. A child copies its parent's labels unless told otherwise, and never copies metadata, so `--metadata` stays.
- **Verify a created issue**: `bd show <id> --json | jq '.[0] | {issue_type, labels, project: .metadata.project, repo: .metadata.repo}'`. Every issue shows its project and repo; a spec also shows `issue_type` `epic` and a `spec` label. Repair a mismatch with `bd update <id> --type epic`, `--add-label spec`, or `--set-metadata project=<name> --set-metadata repo=<repo>`, then verify again.
- **Make an existing issue a child**: `bd update <child-id> --parent <parent-id>`
- **Change an issue's project**: `bd update <id> --set-metadata project=<name> --set-metadata repo=<repo>`
- **Blocking**: native dependencies. At creation, pass `--deps blocked-by:<id>,blocked-by:<id>`. Later, add an edge with `bd dep add <blocked-id> <blocker-id>` and remove one with `bd dep remove <blocked-id> <blocker-id>`. Blockers may belong to other projects. `bd` rejects an edge that would form a cycle. An issue is unblocked when every blocker is closed.
- **Count open blockers**: `bd show <id> --json | jq '[.[0].dependencies[] | select(.dependency_type=="blocks" and .status!="closed")] | length'`. 0 means startable.
- **List dependents**: `bd dep list <id> --direction=up --json`
- **Read an issue**: `bd show <id>` prints the body, labels, metadata, parent, blockers, and comments. For JSON, run `bd show <id> --json --include-comments`, where `created_by` is the reporter. `bd comments <id> --json` gives each comment's `author` and `created_at`.
- **List issues**: `bd list --metadata-field project=<project-name> --status open --sort created -r -n 0 --json --brief | jq '[.[] | {id, title, status, labels, assignee, parent, created_by, created_at}]'` lists oldest first. `-n 0` lifts the 50-row default. Narrow it with `--label <label>` (repeat to require all), `--label-any <label>`, `--parent <id>`, `-t <type>`, or `--status <status>,<status>`; `--all` includes every status. Run **Read an issue** on hits that need the body or comments.
- **List specs**: `bd list -t epic --label spec --metadata-field project=<project-name> -n 0 --json --brief`
- **Comment on an issue**: `bd comment <id> --stdin <<'EOF'`
- **Update a body**: `bd update <id> --body-file -` replaces the whole body. Run `bd show <id>` immediately before, then change only the intended part. Ticking an acceptance criterion turns `- [ ]` into `- [x]`.
- **Close**: confirm the status is not `closed`, because `bd close` on a closed issue keeps the old reason and still exits 0. Post the explanation with **Comment on an issue**, then run `bd close <id> --reason "<one-line reason>"`.
- **Reopen**: `bd update <id> --if-status closed --status open --remove-label resolved,wontfix`
- **Delete**: `bd delete <id>` removes the issue and every dependency edge on it. Reserve it for an issue that should never have existed, and close the rest.

## Pull requests as a triage surface

**PRs as a request surface: no.** Beads has no pull requests, so `/triage` covers issues only.

## Triage roles

`ready-for-agent` is an `open` issue, so a skill asking for that label needs no label. `wontfix` is **Wontfix**. Beads holds no other role; when a skill asks for one, stop and tell the user.

## When a skill says "publish to the issue tracker"

- **A spec** (`/ai-to-spec`): **Create a spec**, with no children.
- **A ticket graph** (`/ai-to-tickets`): **Create a child issue** for each ticket under the spec epic, or under the parent issue the user named, blockers first, each with its `blocked-by` edges. A ticket's project is `<project-name>` unless the conversation named another, and every other project needs its `repo`. Show each ticket's project and repo in the breakdown, and ask for whichever the conversation left open. When the source spec is not an epic, stop and tell the user.
- **Anything else**: **Create an issue**.

## When a skill says "fetch the relevant ticket"

Run **Read an issue**.

## When a skill says "resolve a ticket" or "close work"

Run **Resolve** under Ticket lifecycle.

## Ticket lifecycle

`docs/agents/ticket-lifecycle.md` defines the states and who moves a ticket between them. Each operation below makes one move.

A `blocked` ticket keeps its dependents blocked. An `--if-status` guard writes nothing on a mismatch and exits 13. Exit 13 means the ticket moved, so read it again.

- **Check a named ticket**: `bd show <id> --json | jq '.[0] | {status, assignee, project: .metadata.project, open_blockers: [.dependencies[] | select(.dependency_type=="blocks" and .status!="closed") | .id]}'`. The ticket is claimable when the status is `open`, the assignee is `null`, the project is `<project-name>`, and `open_blockers` is `[]`.
- **Next ticket**: `bd ready --parent <spec-id> --metadata-field project=<project-name> --exclude-type epic --unassigned --sort oldest --json --brief` returns the spec's unassigned `open` tickets with no open blocker. The first result is next.
- **Claim**: `bd update <id> --claim` sets the status to `in_progress` and the assignee to you. It fails when someone else holds the ticket. Then `bd show <id> --json | jq '.[0] | {status, assignee}'` must show `in_progress` and you.
- **Resolve**: post the resolution comment with **Comment on an issue**, then `bd update <id> --if-status in_progress --status closed --add-label resolved --append-notes "resolved: <commit-sha>"`, then `bd show <id> --json | jq '.[0] | {status, labels, notes}'` must show `closed`, `resolved`, and the SHA. Closing unblocks the dependents.
- **Needs a person**: post the failure comment with **Comment on an issue**, then run `bd update <id> --if-status in_progress --status blocked --assignee '' --add-label needs-human`
- **Person clears**: `bd update <id> --if-status blocked --status open --remove-label needs-human`
- **Release an abandoned claim**: `bd unclaim <id>` returns an `in_progress` ticket to `open` with no assignee. It works only on `in_progress`.
- **Wontfix**:
  1. Run **List dependents**. Closing this ticket would unblock them, so each dependent must already be `wontfix`, or lose its edge through `bd dep remove <dependent-id> <id>`.
  2. Run `bd update <id> --status closed --force --add-label wontfix --append-notes "wontfix: <why>"`. `--force` overrides the refusal to close an issue with open blockers; reserve it for wontfix.

## Wayfinding operations

Used by `/wayfinder`. The **map** is an epic, and its **child** issues are the tickets. Maps and their tickets carry only `wayfinder:` labels, plus the `project` metadata. They skip the ticket lifecycle: a ticket stays open until resolved and belongs to its assignee.

- **Map**: **Create an issue** with `-t epic -l wayfinder:map` and the map body: Destination, Notes, Decisions so far, Not yet specified, Out of scope.
- **Child ticket**: **Create a child issue** under `<map-id>` with the label `wayfinder:<type>`, where `<type>` is `research`, `prototype`, `grilling`, or `task`.
- **Blocking**: **Blocking** under Conventions, with every blocker inside the map. Add the edges in a second pass, once every ticket has an ID.
- **Frontier query**: `bd ready --parent <map-id> --exclude-type epic --unassigned --sort oldest --json --brief` drops tickets with an open blocker or an assignee. The first result wins. For a named ticket, check **Count open blockers** and its `assignee`.
- **Claim**: **Claim** under Ticket lifecycle, as the session's first write.
- **Map update**: **Update a body**.
- **Resolve**: post the answer with **Comment on an issue**, run `bd close <id> --reason "<gist>"`, then append `- **<title>** (<id>): <gist>` to the map's Decisions so far. Link assets, such as a research branch, in a comment.
- **Out of scope**: `bd close <id> --reason "out of scope: <why>"`, then append `- **<title>** (<id>): <gist>, <why>` to the map's Out of scope.
- **Invalidated ticket**: update its body, close it with the reason, or **Delete** it when it should never have existed.
