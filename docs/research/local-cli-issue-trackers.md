# Local CLI issue trackers for an AI-agent software factory

Research date: 2026-11-17. Status data (license, last push, latest release) comes from the GitHub, Gitea, and Codeberg APIs on that date. Claims marked **[verified]** were checked against source code or official docs. Claims marked **[inference]** are my reading of the source and have not been tested.

## Summary

The tracker only has to create tickets, model "B waits on A", and let concurrent workers claim tickets safely.

**beads (`bd`)** is the only candidate that covers all six requirements natively. It has a compare-and-swap claim (`bd update <id> --claim`), a combined "claim the next ready ticket" (`bd ready --claim --json`), typed dependencies, labels, and JSON output on every command. Its caveats are size and churn: it runs on an embedded Dolt database, changes very fast, and its atomicity holds per database, not across offline clones that sync later.

**Taskwarrior** is the mature fallback. It has dependencies, a `+READY` virtual tag, tags, UDAs, and JSON export, but no conditional update. Two workers can both "claim" the same task unless every claim goes through an external lock (macOS ships `/usr/bin/lockf`).

The other tools either have no atomic claim (Backlog.md, ticket/`tk`), only do compare-and-swap inside one process (beans), are servers without a first-class CLI for dependencies (Gitea, Redmine), or have no dependency model (git-bug, git-issue, dstask, Fossil, todo.txt).

## Ranked list

### 1. beads (`bd`): recommended

Repo: https://github.com/gastownhall/beads. `steveyegge/beads` now redirects there, and the Go module path is still `github.com/steveyegge/beads`. MIT. Last push 2026-11-17; latest release v1.3.4 on 2026-11-04 ([releases](https://github.com/gastownhall/beads/releases)).

| Req | Verdict | Evidence |
|---|---|---|
| 1 OSI license | Pass. MIT. Its storage engine, Dolt, is Apache-2.0. | [LICENSE](https://github.com/gastownhall/beads/blob/main/LICENSE), [dolthub/dolt](https://github.com/dolthub/dolt) |
| 2 Local on macOS | Pass. `brew install beads`. Embedded mode is the default: Dolt runs in-process, data lives in `.beads/embeddeddolt/`, and no server is needed. An optional local `dolt sql-server` mode exists. | [README](https://github.com/gastownhall/beads/blob/main/README.md), [docs/architecture/index.md](https://github.com/gastownhall/beads/blob/main/docs/architecture/index.md) |
| 3 Dependencies + ready query | Pass. `bd dep add`, edge types such as `blocks` and `waits-for`, `bd ready` ("open, no active blockers"), `bd blocked`, and `bd dep cycle` detection. | [docs/CLI_REFERENCE.md](https://github.com/gastownhall/beads/blob/main/docs/CLI_REFERENCE.md) |
| 4 Custom labels | Pass. `bd label add/list/remove`. | [docs/core-concepts/labels.md](https://github.com/gastownhall/beads/blob/main/docs/core-concepts/labels.md) |
| 5 Atomic claim | Pass on a single database. See below. | [internal/storage/issueops/claim.go](https://github.com/gastownhall/beads/blob/main/internal/storage/issueops/claim.go), [issueops/claimer.go](https://github.com/gastownhall/beads/blob/main/issueops/claimer.go), [docs/multi-agent/coordination.md](https://github.com/gastownhall/beads/blob/main/docs/multi-agent/coordination.md) |
| 6 CLI / JSON | Pass. Built CLI-first for agents; `--json` on all commands; `bd batch` runs several writes in one transaction. | [README](https://github.com/gastownhall/beads/blob/main/README.md), [docs/architecture/dolt.md](https://github.com/gastownhall/beads/blob/main/docs/architecture/dolt.md) |

How the claim works **[verified, source]**:
- `ClaimIssueInTx` reads the issue inside a SQL transaction. It then runs `UPDATE issues SET assignee=?, status='in_progress', row_lock=<fresh random> WHERE id=? AND row_lock=<value read> AND status IN (<claimable statuses>)`. If zero rows change, the claim is refused with `ErrAlreadyClaimed` or `ErrNotClaimable`, unless the same actor already holds the ticket; that case is an idempotent success. ([claim.go](https://github.com/gastownhall/beads/blob/main/internal/storage/issueops/claim.go))
- `ClaimReadyIssueInTx` computes readiness and claims the first ready ticket in the same transaction, skipping tickets a racing worker took first. This is what `bd ready --claim` uses. (same file)
- Dolt has no real row locking and merges concurrent commits cell by cell. beads therefore rewrites a shared `row_lock` cell on every status or assignee change, so two concurrent writers always collide and the loser retries. ([lease.go](https://github.com/gastownhall/beads/blob/main/internal/storage/issueops/lease.go))
- Claims also create a lease. Dead workers are recovered with `bd heartbeat` and `bd reclaim`. ([CLI_REFERENCE.md](https://github.com/gastownhall/beads/blob/main/docs/CLI_REFERENCE.md))

Scope of the atomicity:
- Embedded mode allows one writer at a time, enforced by a file lock. Concurrent `bd` processes serialize; contention can show up as "database is locked". For sustained concurrent agents the docs recommend server mode. ([dolt.md](https://github.com/gastownhall/beads/blob/main/docs/architecture/dolt.md))
- Across machines or clones that sync with `bd dolt push/pull`, nothing prevents two offline clones from claiming the same ticket. **[inference]** The `row_lock` design should make the second pull report a merge conflict rather than merge silently, so you detect the double claim afterward instead of preventing it. The docs warn about races in multi-clone workflows. ([architecture/index.md](https://github.com/gastownhall/beads/blob/main/docs/architecture/index.md), [recovery/merge-conflicts.md](https://github.com/gastownhall/beads/blob/main/docs/recovery/merge-conflicts.md))
- For a single Mac running every worker against one `.beads` database, the claim is atomic.

### 2. Taskwarrior 3 (`task`): mature, but claiming needs an external lock

Repo: https://github.com/GothenburgBitFactory/taskwarrior. MIT. Last push 2026-11-17; latest release v3.5.0 on 2026-08-16. Storage is TaskChampion (SQLite), at https://github.com/GothenburgBitFactory/taskchampion.

| Req | Verdict | Evidence |
|---|---|---|
| 1 | Pass. MIT. | [repo](https://github.com/GothenburgBitFactory/taskwarrior) |
| 2 | Pass. Local SQLite replica; syncing to a server is optional. | [taskchampion sqlite storage](https://github.com/GothenburgBitFactory/taskchampion/blob/main/src/storage/sqlite/inner.rs) |
| 3 | Pass. `depends:<id>`, virtual tags `+BLOCKED`, `+UNBLOCKED`, `+BLOCKING`, and `+READY` ("pending, not blocked, and either not scheduled, or scheduled before now"). | [taskwarrior.org/docs/tags](https://taskwarrior.org/docs/tags/), [src/Task.cpp](https://github.com/GothenburgBitFactory/taskwarrior/blob/develop/src/Task.cpp) |
| 4 | Pass. Free-form `+tag` tags, plus user-defined attributes (UDAs) for custom fields. | [docs/tags](https://taskwarrior.org/docs/tags/), [docs/udas](https://taskwarrior.org/docs/udas/) |
| 5 | **Not native.** | See below. |
| 6 | Pass. Mature CLI with powerful filters; `task export` emits JSON; `task import` accepts it. | [docs/commands/export](https://taskwarrior.org/docs/commands/export/) |

Why the claim is not atomic **[verified source; conclusion is inference]**:
- Each storage write runs in a SQLite `BEGIN IMMEDIATE` transaction. ([inner.rs](https://github.com/GothenburgBitFactory/taskchampion/blob/main/src/storage/sqlite/inner.rs))
- Taskwarrior reads tasks first and later calls `replica()->commit_operations(ops)`. ([src/TDB2.cpp](https://github.com/GothenburgBitFactory/taskwarrior/blob/develop/src/TDB2.cpp))
- `apply_operations` overwrites property values without checking the operation's `old_value` against the stored value. ([src/taskdb/apply.rs](https://github.com/GothenburgBitFactory/taskchampion/blob/main/src/taskdb/apply.rs))
- So `task 'uuid:X start.none:' start` evaluates its filter outside the write transaction, and two processes can both "win". On-modify hooks have the same race.

Workaround: run every claim inside `lockf /path/claim.lock sh -c 'task +READY limit:1 export ...; task <uuid> start; task <uuid> modify assignee:<w>'`, using `/usr/bin/lockf`, which ships with macOS. This is safe on one machine only. `assignee` would be a UDA.

### 3. Gitea (server) + `tea` CLI: server-grade, claim needs a workaround

Gitea: https://github.com/go-gitea/gitea, MIT, latest v28.4.0, last push 2026-11-17. tea: https://gitea.com/gitea/tea, MIT, v0.16.0 on 2026-09-10. (The GitHub mirror `go-gitea/tea` is archived.)

| Req | Verdict | Evidence |
|---|---|---|
| 1 | Pass. MIT. | [repo](https://github.com/go-gitea/gitea) |
| 2 | Pass. A single Go binary with SQLite runs locally; Homebrew has a formula. It is still a server you have to run. | [gitea repo](https://github.com/go-gitea/gitea) |
| 3 | Partial. Issue dependencies exist in the API (`/repos/{o}/{r}/issues/{i}/dependencies`, `/blocks`). There is no "ready" query, so you compute it client-side. | [routers/api/v1/api.go](https://github.com/go-gitea/gitea/blob/main/routers/api/v1/api.go) |
| 4 | Pass. Repo and org labels; `tea labels`. | [tea docs/CLI.md](https://gitea.com/gitea/tea/src/branch/main/docs/CLI.md) |
| 5 | Workaround only. See below. | |
| 6 | Partial. `tea` supports `--output json` for issues and labels but has no dependency subcommand; `tea api` sends raw API calls. | [tea docs/CLI.md](https://gitea.com/gitea/tea/src/branch/main/docs/CLI.md) |

Claim:
- **[verified]** `EditIssueOption` has a `content_version` field. `EditIssue` returns HTTP 409 when it is stale, and the DB-level check in `ChangeContent` covers concurrent requests. ([modules/structs/issue.go](https://github.com/go-gitea/gitea/blob/main/modules/structs/issue.go), [routers/api/v1/repo/issue.go](https://github.com/go-gitea/gitea/blob/main/routers/api/v1/repo/issue.go))
- The version only guards the body. The source has a TODO saying the mutations are not yet wrapped in one transaction.
- **[inference, untested]** A claim could be one PATCH that changes the body (for example, appending `claimed-by: w1`), passes `content_version`, and sets `assignees`. The body is processed before the assignees, so the loser should get a 409 before its assignee write happens. This is a hack that depends on code ordering.

Forgejo (GPL-3.0, v17.0.1 on 2026-10-26, https://codeberg.org/forgejo/forgejo) has the same dependency feature. I did not find `content_version` in its `modules/structs/issue.go`, so the workaround does not apply to it. Its CLI, `fj` (forgejo-cli, v0.7.0), is at https://codeberg.org/forgejo-contrib/forgejo-cli.

### 4. beans: good fit on paper, but compare-and-swap only works inside one process

Repo: https://github.com/hmans/beans. Apache-2.0. v0.4.2 released 2026-03-10; last push 2026-04-06, so about 7 months without activity.

| Req | Verdict | Evidence |
|---|---|---|
| 1 | Pass. Apache-2.0. | [repo](https://github.com/hmans/beans) |
| 2 | Pass. Flat Markdown files in the repo. | [README](https://github.com/hmans/beans/blob/main/README.md) |
| 3 | Pass. `blocking`/`blockedBy` relations; `beans list --ready` / `--is-blocked`. | [schema.graphqls](https://github.com/hmans/beans/blob/main/internal/graph/schema.graphqls), [list.go](https://github.com/hmans/beans/blob/main/internal/commands/list.go) |
| 4 | Pass. Tags (`--tag`). | [create.go](https://github.com/hmans/beans/blob/main/internal/commands/create.go) |
| 5 | Partial. `beans update --if-match <etag>` ("optimistic locking"). | [update.go](https://github.com/hmans/beans/blob/main/internal/commands/update.go), [pkg/beancore/core.go](https://github.com/hmans/beans/blob/main/pkg/beancore/core.go) |
| 6 | Pass. `--json` on list, show, and update; GraphQL. | [list.go](https://github.com/hmans/beans/blob/main/internal/commands/list.go) |

The ETag check computes a hash of the file on disk and compares it while holding an in-memory `sync.RWMutex`. There is no file lock anywhere in the repo. **[inference]** Two separate `beans` CLI processes can therefore both pass the check before either writes (a time-of-check/time-of-use race). It is atomic only if every writer goes through one long-lived process, such as `beans-serve`.

### 5. Backlog.md: good dependency model, no conditional claim

Repo: https://github.com/MrLesk/Backlog.md. MIT. v1.55.3 on 2026-10-23; last push 2026-11-17.

| Req | Verdict | Evidence |
|---|---|---|
| 1 | Pass. MIT. | [repo](https://github.com/MrLesk/Backlog.md) |
| 2 | Pass. Markdown files; can run without git (`backlog init --no-git`). | [README](https://github.com/MrLesk/Backlog.md/blob/main/README.md) |
| 3 | Pass. `--dep`; `task list --ready`; JSON includes `isReady` and `readiness.blockingDependencies`. Unknown dependencies count as blocking. | [CLI-INSTRUCTIONS.md](https://github.com/MrLesk/Backlog.md/blob/main/CLI-INSTRUCTIONS.md) |
| 4 | Pass. `-l` labels. | same |
| 5 | **Fail natively.** | See below. |
| 6 | Pass. Stable, versioned `--json` on read commands; MCP server. | [README](https://github.com/MrLesk/Backlog.md/blob/main/README.md) |

Edits take a per-task lock (`proper-lockfile`, zero retries) and re-read the task inside it. This prevents lost updates: a concurrent editor fails fast. ([src/core/backlog.ts](https://github.com/MrLesk/Backlog.md/blob/main/src/core/backlog.ts), [src/file-system/operations.ts](https://github.com/MrLesk/Backlog.md/blob/main/src/file-system/operations.ts)) But there is no "only if unassigned" condition, so a second claim that runs after the first finishes simply overwrites it. A safe claim needs an external lock, as with Taskwarrior. Tasks can also live on several git branches and worktrees, so readiness depends on what each checkout can see.

### 6. Redmine: has optimistic locking, but heavy and no first-class CLI

Mirror: https://github.com/redmine/redmine (GPL-2.0; GitHub reports NOASSERTION). Version 7.0.3 in `lib/redmine/version.rb`; last push 2026-11-17.

- Req 3: issue relations (blocks/blocked by, precedes/follows) **[known from Redmine docs, not re-verified here]**. There is no ready query.
- Req 4: no native labels; you would use categories or custom fields.
- Req 5 **[verified]**: `lock_version` is a safe attribute on `Issue`, and the update path rescues `ActiveRecord::StaleObjectError`. ([app/models/issue.rb](https://github.com/redmine/redmine/blob/master/app/models/issue.rb), [issues_controller.rb](https://github.com/redmine/redmine/blob/master/app/controllers/issues_controller.rb)) This makes compare-and-swap possible through the REST API by sending `lock_version`. The exact API response on conflict is unverified.
- Req 6: REST/JSON API only; the CLIs are third-party.
- Runs a Rails stack locally. It meets the bar on paper, but it is a poor fit for a CLI agent pipeline.

### 7. ticket (`tk`): simplest option, no concurrency control

Repo: https://github.com/wedow/ticket. MIT. v0.3.2 on 2026-02-03. A single bash script that stores Markdown and YAML in `.tickets/`. It has `tk dep`, `tk ready`, `tk blocked`, `--tags`, and `tk query` (JSON via jq). ([README](https://github.com/wedow/ticket/blob/master/README.md)) `tk start` rewrites the file with `sed` and `mv`, with no lock or condition. ([ticket](https://github.com/wedow/ticket/blob/master/ticket)) It fails requirement 5 unless wrapped in `lockf`.

## Comparison table

| Tool | 1 OSI | 2 Local macOS | 3 Deps + ready | 4 Labels | 5 Atomic claim | 6 CLI/JSON | Last activity |
|---|---|---|---|---|---|---|---|
| beads | MIT | embedded Dolt | yes + `bd ready` | yes | **native CAS**, per DB; `ready --claim` | yes, `--json` | 2026-11-17 |
| Taskwarrior 3 | MIT | SQLite | yes + `+READY` | tags + UDAs | no; external `lockf` | yes, `export` JSON | 2026-11-17 |
| Gitea + tea | MIT | local server | API only, no ready | yes | body `content_version` hack | partial | 2026-11-17 |
| beans | Apache-2.0 | files | yes + `--ready` | tags | `--if-match`, in-process only | yes | 2026-04-06 |
| Backlog.md | MIT | files | yes + `--ready` | yes | no (lock stops lost updates only) | yes | 2026-11-17 |
| Redmine | GPL-2.0 | Rails server | relations, no ready | no (custom fields) | `lock_version` via REST | REST only | 2026-11-17 |
| ticket (`tk`) | MIT | files | yes + `tk ready` | tags | no | jq JSON | 2026-03-15 (last commit) |

## Excluded

| Tool | Reason | Source |
|---|---|---|
| git-bug | No dependencies and no assignee command. Its CLI covers comments, labels, status, and titles only. Merges are CRDT-based, so there is no exclusive claim. GPL-3.0, v0.12.0 (2026-11-07). | [commands/bug](https://github.com/git-bug/git-bug/tree/trunk/commands/bug), [data-model.md](https://github.com/git-bug/git-bug/blob/trunk/doc/design/data-model.md) |
| git-issue | No dependencies; tags and assignees only. Last push 2025-10-17. | [README](https://github.com/dspinellis/git-issue/blob/master/README.md) |
| dstask | No dependencies; tags and projects only. Git-synced with no locking. | [README](https://github.com/naggie/dstask/blob/master/README.md) |
| Task Master (task-master-ai) | Not OSI: MIT plus Commons Clause. It also needs an LLM provider for its core features. | [LICENSE](https://github.com/eyaltoledano/claude-task-master/blob/main/LICENSE) |
| Fossil tickets | `fossil ticket add/set/show` has no dependency model, no conditional update, and output is TSV. | [fossil help ticket](https://fossil-scm.org/home/help/ticket) |
| Forgejo + `fj` | Same as Gitea, but I found no `content_version` field, so it has no compare-and-swap path at all. GPL-3.0. | [modules/structs/issue.go](https://codeberg.org/forgejo/forgejo/src/branch/forgejo/modules/structs/issue.go) |
| Plane | AGPL-3.0 and has blocking/blocked_by relations, but no first-class CLI (unofficial ones only), no compare-and-swap, and a heavy Docker stack. Self-hosted relation endpoints are reported as inconsistent. | [API docs](https://developers.plane.so/api-reference/work-item-relations/overview), [forum report](https://forum.plane.so/t/work-item-relation-tools-list-work-item-relation-definitions-list-work-item-relations-return-404-via-mcp-server-on-self-hosted-ce/274), [kimrgrey/plane-cli](https://github.com/kimrgrey/plane-cli) |
| Taiga | Heavy server and no first-class CLI. **[inference]** It has a "blocked" flag but no ticket-to-ticket dependency links. | [taiga-back](https://github.com/taigaio/taiga-back) |
| Kanboard, Vikunja | Both have "blocks / is blocked by" task links and APIs (MIT and AGPL-3.0), but neither has a first-class tracker CLI or a conditional update. Not verified further. | [kanboard](https://github.com/kanboard/kanboard), [vikunja](https://github.com/go-vikunja/vikunja) |
| Huly (Linear clone) | EPL-2.0 multi-service platform with no tracker CLI. | [hcengineering/platform](https://github.com/hcengineering/platform) |
| todo.txt-cli | No dependency model in the format; only add-ons. GPL-3.0. | [todo.txt-cli](https://github.com/todotxt/todo.txt-cli) |

## Open questions and risks

- **beads churn.** The `[Unreleased]` section of the CHANGELOG is about 5,700 lines on top of v1.3.4, and releases ship days apart ([CHANGELOG.md](https://github.com/gastownhall/beads/blob/main/CHANGELOG.md)). Pin a version and test upgrades. The repo has also moved from `steveyegge` to `gastownhall` ownership.
- **beads scope.** It ships many extras (molecules, wisps, gates, swarms, memory, federation). You only need create, dep, ready, claim, and close. `bd init` writes AGENTS.md and agent hooks by default; use `--skip-agents` or `--stealth` if the factory manages its own prompts ([README](https://github.com/gastownhall/beads/blob/main/README.md)).
- **beads embedded vs server mode.** Embedded mode serializes writers with a file lock. Under many parallel workers, expect lock contention and per-command engine startup cost. Benchmark both modes with your real worker count ([dolt.md](https://github.com/gastownhall/beads/blob/main/docs/architecture/dolt.md)).
- **Multi-machine.** No candidate gives a cross-machine atomic claim without one central writer. If workers ever run on several hosts, point them all at one beads Dolt server (or one Gitea or Redmine server) instead of syncing clones.
- **Untested.** I did not run concurrent claim tests. A short stress test (N workers running `bd ready --claim --json` against one database, then checking for duplicates) should be the first spike.
- **Gitea workaround.** The `content_version` claim hack depends on the order of operations inside `EditIssue` and could break in any release.
