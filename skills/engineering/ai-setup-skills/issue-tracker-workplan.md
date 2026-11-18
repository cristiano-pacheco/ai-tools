# Issue tracker: Workplan

Implementation tickets follow `docs/agents/ticket-lifecycle.md`. Read it whenever you fetch a ticket to work on it: claim the ticket before any other step.

This repo resolves to project name **`<project-name>`** (basename of `git rev-parse --show-toplevel`). Its Workplan project is **`<canonical-repository-path>`**, the canonical physical repository path registered by setup.

Specs are `spec` Workplans, wayfinding maps are `wayfinder` Workplans, and their child issues are Tickets. Workplan stores Ticket prerequisites, project assignment, lifecycle, and reviews.

## CLI contract

Use only `wp --json` for tracker reads and writes. Before the first tracker call, load `ai-workplan` and its machine-output reference. For each command family needed by the current operation, read its reference and check the command's `--help` for current flags and response fields.

Require `schema_version: 1`. Read success from `data`, branch on `error.code`, and ignore additive fields. Follow `page.next_cursor` with unchanged filters whenever completeness is required. Stop all tracker calls on `database_busy`. Pass Markdown through a user-private temporary file and remove it after the call, including on failure.

Ticket identifiers are `<workplan-slug>/<NN>-<ticket-slug>`. Slugs match `[a-z0-9]+(-[a-z0-9]+)*` and are at most 63 bytes. When publishing Tickets, pass the intended canonical project explicitly instead of relying on working-directory discovery.

## Skill routing

Use the tracker-neutral workflows; this document supplies their Workplan operations: `ai-to-spec` publishes a `spec` Workplan, `ai-to-tickets` publishes its Ticket graph, `ai-implement` executes one Ticket, and `wayfinder` charts or works through a `wayfinder` Workplan. `ai-workplan` is only the CLI reference.

## Publish a spec

When `ai-to-spec` says to publish:

1. Preserve its final Markdown exactly. Derive a valid slug from the title, list every Workplan because slugs are global, and use the base slug or its lowest free numeric suffix (`-2`, `-3`, …), truncating the base to fit.
2. Set `--source` only for an explicitly identified source that resolves to one slug; similarity and recency establish no lineage.
3. Run `wp --json workplan create --type spec --slug <slug> --title <title> [--source <source-slug>] --content <file>` and verify that the returned type, slug, title, source, and `content_markdown` exactly match the draft.

On `already_exists`, retry only the create with the next suffix and unchanged title, source, and content. Preserve every existing Workplan; any other error ends publication. Workplan has no labels; newly created Tickets start with status `ready-for-agent`.

## Fetch tracker context

Resolve an explicit spec slug first, then the canonical result of an immediately preceding publication. Otherwise ask for the exact slug; similarity and recency are not selectors. Run `wp --json workplan show <slug>` and use stored `content_markdown`, never a conversation copy.

Fetch a Ticket with `wp --json ticket show <complete-identifier>`. When review history matters, read every page of `wp --json review list <complete-identifier>`; reviews are immutable and oldest first.

To work the Ticket, claim it next, before any other step, with **Claim** under Implementation ticket lifecycle. When the claim fails, stop and report; another agent holds the Ticket.

## Publish a ticket graph

For the graph approved in `ai-to-tickets`:

1. Give each Ticket a literal type: `research`, `prototype`, `grilling`, or `task`; use `task` for production behavior. Resolve each Ticket independently to an explicit registered project path, or intentionally choose `--no-project`. Only setup registers missing projects. Validate and topologically order the graph with every prerequisite before its dependents.
2. Before writing, list every Ticket under the spec across all projects. An existing drafted slug is compatible only when its title, type, exact body, project, and complete prerequisite set match. Compatible Tickets must form a prefix of the ordered graph; otherwise report a publication conflict and preserve tracker state.
3. Create the missing suffix in order with `wp --json ticket create`, the Workplan and draft fields, the explicit project selection, and every direct `--prerequisite`. Build prerequisite identifiers only from successful Workplan responses. Creation sets status `ready-for-agent`; it has no status flag. Verify the complete returned Ticket and prerequisite set before creating a dependent.

On failure, remove the temporary file, report the typed error and identifiers already created, and stop without rollback or parent-Workplan mutation.

## Implementation ticket lifecycle

`docs/agents/ticket-lifecycle.md` defines the states and who moves a Ticket between them. Workplan's status catalog has only `ready-for-agent`, `claimed`, and `resolved`, so it stores them as:

| State | Storage |
| --- | --- |
| `ready-for-agent` | status `ready-for-agent`, `claim` is `null` |
| `claimed` | status `claimed` |
| `needs-human` | status `claimed`, and the newest review starts with `- needs-human:` |
| `resolved` | status `resolved`, and the newest review holds the commit SHA |
| `wontfix` | soft-deleted, after a review that starts with `- wontfix:` |

Claims have no owner or expiry. `claimed` is the lock: Workplan sets it atomically, and no other agent can claim the Ticket while it holds. A `needs-human` Ticket keeps that lock, so no agent picks it up before a person clears it.

- **Check a named ticket**: `wp --json ticket show <complete-identifier>`. It is claimable when the status is `ready-for-agent` and every prerequisite is `resolved`.
- **Next ticket**: `wp --json ticket ready` from this repository, with only user-supplied filters; the first Ticket is next.
- **Claim**: `wp --json ticket claim <complete-identifier>` for a named Ticket, or `wp --json ticket claim-next` with the same filters as **Next ticket**. Claiming is atomic: an error means another agent holds the Ticket, so stop. `no_ready_ticket` is clean no-work. Keep the complete claim response as the execution snapshot.
- **While claimed**: Workplan rejects `ticket update` on a claimed Ticket, so leave `content_markdown` unchanged and record criterion evidence during the run instead of ticking boxes.
- **Resolve**: store the exact review report with `wp --json review add <complete-identifier> --content <file>`, ending with a `- resolved: <commit-sha>` line. Then run `wp --json ticket resolve <complete-identifier>` and verify status `resolved`. `ticket status` does not replace `claim` or `resolve`.
- **Needs a person**: store the failure comment with `wp --json review add <complete-identifier> --content <file>`, then confirm the status is still `claimed`. Preserve the worktree.
- **Person clears**: `wp --json ticket status <complete-identifier> ready-for-agent`
- **Release an abandoned claim**: `wp --json ticket status <complete-identifier> ready-for-agent`, run by a person.
- **Wontfix**: `wp --json dependency list <complete-identifier>` lists its prerequisites and dependents. Each dependent must be wontfix first, or have its edge removed with `wp --json dependency remove <dependent> <complete-identifier>`; remove the Ticket's own prerequisite edges the same way. Then store a review starting with `- wontfix: <why>` and run `wp --json ticket delete <complete-identifier>`. Delete fails while the Ticket is claimed or dependency-linked; set a claimed Ticket to `ready-for-agent` first. `ticket restore` undoes the delete.

## Labels

Workplan has no label resources or `--label` flag. Ticket creation sets status `ready-for-agent`, satisfying requests from tracker-neutral skills to apply that label. Spec publication requires no label or status change. Map wayfinding labels to native Workplan and Ticket types as described below. Claim and resolve Tickets through the lifecycle operations.

## Wayfinding operations

Used by `/wayfinder`. The **map** is one `wayfinder` Workplan; its **child tickets** belong to that Workplan.

- **Map:** create it with `wp --json workplan create --type wayfinder --slug <slug> --title <title> --content <file>`. The Workplan type replaces the tracker-neutral `wayfinder:map` label.
- **Child ticket:** create it under the map with `wp --json ticket create --workplan <map-slug> ... --type <research|prototype|grilling|task> --content <file> --project <canonical-repository-path>`. The Ticket type replaces its tracker-neutral `wayfinder:<type>` label.
- **Blocking:** pass every known direct prerequisite atomically during Ticket creation. Add a later edge with `wp --json dependency add <blocked-ticket> <prerequisite>`. Keep every edge within the map and the graph acyclic.
- **Frontier:** run `wp --json ticket ready --workplan <map-slug> --project <canonical-repository-path>` and take its first Ticket. A user-named Ticket must appear in that frontier.
- **Claim:** run `wp --json ticket claim <complete-identifier>` before work.
- **Map update:** immediately before replacing map content, fetch the latest Workplan, change only the intended section, then run `wp --json workplan content <map-slug> --content <file>`; this command replaces the whole body.
- **Resolve:** store the exact answer with `wp --json review add <complete-identifier> --content <file>`, resolve the Ticket, then append `- **<title>** (<complete-identifier>): <one-line gist>` under **Decisions so far**. Workplan has no stable resource URL.
- **New fog and scope changes:** create and wire newly specifiable Tickets, then remove their questions from **Not yet specified** in the same map update. For a Ticket ruled out of scope, store the rationale as its review, resolve it, and append its pointer and reason under **Out of scope**, not **Decisions so far**.
