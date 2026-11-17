# Issue tracker: Obsidian

## Output to Obsidian

Write specs, tickets, wayfinding maps, and tracker comments directly to the user's Obsidian vault on the local filesystem, without MCP. Group them by project.

**Vault root:** resolve `<vault>` from `$OBSIDIAN_AI_VAULT`. If unset, use `$HOME/Documents/obsidian/obsidian`. Use absolute filesystem paths with the read/write/edit tools. Keep wikilinks vault-root-relative, as in `[[engineering/...]]`.

### Resolve the project base path

1. Use the configured project name `<project-name>` for `<project>`. If not configured, derive it from the basename of `git rev-parse --show-toplevel`.
2. If no project is configured and the command fails, propose a kebab-case name from `basename "$PWD"` and confirm it with the user before writing.
3. Paths below are relative to the feature directory, `<vault>/engineering/<project>/workplans/<feature>/`.

## Conventions

- One directory per feature
- The spec is `spec.md`
- Write one file per implementation ticket at `issues/<NN>-<slug>.md`. Number tickets from `01` in dependency order, blockers first. Never combine tickets into one file
- Implementation tickets carry YAML frontmatter, defined in [Implementation ticket frontmatter](#implementation-ticket-frontmatter)
- Claim a ticket by setting its status to `claimed` and saving before work starts. Only one agent works a claimed ticket at a time. Filesystem edits do not provide atomic claims, so one dispatcher (a person or `ai-implement-spec`) starts each ticket
- Comments and conversation history append to the bottom of the file under a `## Comments` heading

## When a skill says "publish to the issue tracker"

Create the artifact at the path defined in Conventions or Wayfinding operations. Create directories as needed. Use the per-ticket template from `ai-to-tickets` for implementation issues. Preserve existing files and reuse an identical published ticket. Report conflicting content or numbering before writing. Leave the parent spec unchanged.

## When a skill says "fetch the relevant ticket"

Read the complete referenced file, including comments. Resolve an issue number within the identified feature's `issues/` directory; if the feature or ticket is ambiguous, ask for the exact path rather than selecting by similarity or recency.

## Implementation ticket frontmatter

Implementation issues (the `issues/NN-slug.md` tickets produced from a spec) start with this frontmatter:

```yaml
---
status: ready-for-agent
type: task
blocked_by: ["01", "03"]
---
```

- `status` is one of `ready-for-agent`, `claimed`, `needs-human`, `resolved`, or a triage role from `triage-labels.md`.
- `blocked_by` lists the two-digit numbers of tickets in the same feature that must be resolved first, or `[]`. Every entry must name an existing ticket. A missing or ambiguous entry blocks execution.
- Change one field by editing its frontmatter line. Preserve the rest of the file.

## Implementation ticket lifecycle

Tickets move `ready-for-agent → claimed → resolved`, or `claimed → needs-human`. A ticket is claimable when its status is `ready-for-agent` and every ticket in `blocked_by` is `resolved`. A person clears a `needs-human` obstacle and sets the status back to `ready-for-agent`.

- The `- [ ]` checklist items are the **acceptance criteria**. Tick each to `- [x]` as soon as it is verifiably done (code, config, and tests all observable).
- Resolve only after every criterion is ticked, the required checks pass, the review has no unresolved Standards or Spec findings, and the reviewed change is committed. Set `status: resolved` and read back the file to verify the saved state. A resolved ticket gets no comment; the commit records the work.
- To mark a ticket as needing a person, set `status: needs-human`, leave unverified criteria unticked, and preserve the worktree. Append the failure comment below under `## Comments`.

The failure comment records only what went wrong, one fact per line, with no prose:

```markdown
- needs-human: <the obstacle in one sentence>
- action: <what a person must do>
- review: <file:line> <unresolved finding>
```

Write one `review:` line per unresolved review finding and omit the line when there are none.

## Wayfinding operations

Used by `/wayfinder`. The **map** is a file with one **child** file per ticket.

- **Map**: `map.md` (the Notes / Decisions-so-far / Fog body).
- **Child ticket**: `issues/NN-<slug>.md`, numbered from `01`, with the question in the body. A `Type:` line records the ticket type (`research`/`prototype`/`grilling`/`task`); a `Status:` line records `claimed`/`resolved`.
- **Blocking**: a `Blocked by: NN, NN` line near the top. A ticket is unblocked when every file it lists is `resolved`.
- **Frontier**: scan `issues/` for files that are open, unblocked, and unclaimed; first by number wins.
- **Resolve**: append the answer under an `## Answer` heading, set `Status: resolved`, then append a context pointer (gist + link) to the map's Decisions-so-far in `map.md`.
