---
name: ai-brag-document
description: Turn work into evidence-backed impact statements (action → result → evidence) in a single Obsidian brag document. Use for "brag", "log my work", "what did I do", performance/self-review, promo packet, weekly update, status report, or accomplishments. Starts from a feature's vault docs (PRD/tech-spec/tasks/notes) or mines git commits and PRs.
---

# Brag Document — Work Impact Writer

Turn engineering work into evidence-backed impact statements for performance reviews, self-reviews, promotion packets, and weekly updates. This skill is part of the spec-driven workflow: when you point it at a feature, it pulls that feature's PRD, tech spec, tasks, and implementation notes from Obsidian so the entries are grounded in what was actually built and why it mattered. Otherwise it interviews you and mines git history and PRs.

DO NOT USE FOR: project management, sprint planning, time tracking, ticket creation, or writing a launch announcement to "brag to the team" about a feature (that's marketing copy, not a work-impact entry — confirm intent if ambiguous).

## Two ways to start

**(A) With a feature/task reference** — the user names a feature (e.g. "brag about the queue-routing work", "write impact statements for the prd-queue-routing feature"). Read that feature's documents from the vault and use them as the primary source of context (what shipped, why, and the evidence trail). See **Feature-grounded workflow** below.

**(B) Without a reference** — the user asks generally ("what did I do last week?", "prep for my review"). Drive it from git/PRs and a guided interview, asking the questions needed to produce strong entries. See **Backfill workflow** and **Guided interview** below.

If it's unclear which applies, ask: "Do you want this tied to a specific feature/project doc, or a general scan of your recent work?"

## Output to Obsidian

All output goes to a single brag document in the user's Obsidian vault, written **directly on the local filesystem** (no MCP). Unlike the other ai-* skills, this one is **not** grouped by project — your accomplishments across every repo accumulate in one place.

**Vault root (default):** `$HOME/Documents/obsidian/obsidian` — override by telling the skill a different absolute path. Use the `Read`/`Write`/`Edit` tools with the **absolute** path.

### The brag document — one directory, one file

Everything goes into `<vault>/brag-document/brag-document.md` (a single directory at the vault root holding a single file).

It is a running, accumulating log, so you **append** to it — **never overwrite it blindly**, that would erase your history. Read it first with the `Read` tool (creating the file with `Write` if it doesn't exist yet) and skip any entry already present (match on PR number, commit, or feature). Then add the new entries with the `Edit` tool: either after the last entry, or under an existing heading (a week, a theme, or a project) by inserting right after that heading. (If you use `Write`, write back the full existing content plus the new entries.) Review packs are added as a new dated section in this same file — not a separate file.

### Tag each entry with its project

Even though everything lives in one file, label each entry with the project it came from so the document stays navigable. Detect the project name from the repo:

1. Run `git rev-parse --show-toplevel`; the basename is the project name.
2. If the current directory is not a git repo, ask the user which project/label the work belongs to.

Use it as a subsection heading (e.g. `### communication-hub`) or an inline `[communication-hub]` tag on the entry.

## Entry format — the impact contract

Every entry uses impact-first framing with three required parts:

```
Did [action] → [result/impact] → [evidence]
```

**Do not output an entry unless it includes all three parts.** If evidence is missing, ask for it or mark it `(evidence needed)` — never silently omit.

### Anti-patterns

| ❌ Don't | ✅ Do instead |
|---------|--------------|
| "Fixed a bug in auth" | "Fixed token refresh race condition → eliminated 401s affecting 12% of API calls → PR #247" |
| "Worked on dashboards" | "Built latency dashboard in Grafana → on-call detects P95 spikes in <2min → deployed to prod" |
| Invent a metric: "saved 40% of eng time" | Ask: "Do you have a rough estimate, or should I keep this qualitative?" |
| One entry per commit | Group related commits into one entry with the highest-impact framing |
| Passive voice: "The pipeline was improved" | Active voice: "Built CI matrix → caught Windows-only bug before release" |
| List technologies used | State the outcome: "Migrated 4 services to IaC → deploy time 45min → 8min" |
| Silently drop weak entries | Mark `(evidence needed)` and present for the user to fill in |

## Evidence ladder

Not every entry needs a metric. Use the strongest evidence available, and never invent one to fill a gap.

| Strength | Evidence type | Example |
|----------|--------------|---------|
| 🥇 Best | Quantified metric | "Reduced P95 latency from 800ms to 120ms" |
| 🥈 Strong | PR, commit, or doc link | "PR #312, tech spec in the vault" |
| 🥉 Good | Observable outcome | "Unblocked Team X", "Resolved Sev2 incident Y" |
| ✅ Acceptable | Qualitative + context | "Reduced on-call toil — see updated runbook" |
| ⚠️ Weak | Activity only | "Worked on auth" — reframe or mark `(evidence needed)` |

## Categories

| ID | Emoji | Use for |
|----|-------|---------|
| `pr` | 🚀 | Merged PRs, shipped features |
| `bugfix` | 🐛 | Bug fixes, incident patches |
| `infrastructure` | 🏗️ | Infra, deployments, migrations |
| `investigation` | 🔍 | Root cause analysis, debugging |
| `collaboration` | 🤝 | Reviews, mentoring, design discussions |
| `tooling` | 🔧 | Dev tools, scripts, automation |
| `oncall` | 🚨 | Incident response, on-call wins |
| `design` | 📐 | Design docs, architecture decisions |
| `documentation` | 📝 | Docs, runbooks, guides |

## Feature-grounded workflow (mode A)

When the user references a feature, the spec docs are your richest, most accurate source of context — they tell you what was built, why it mattered, and where the evidence lives.

### Step 1: Resolve the feature in the vault

List `<vault>/engineering/<project>/workplans` (`ls -1`) and match the feature the user named; if ambiguous or missing, ask.

### Step 2: Read the feature's documents

Read whichever of these exist with the `Read` tool, and extract:

- `…/workplans/<feature>/prd.md` — **why it mattered**: the problem, the users/beneficiaries, the objectives and success metrics. This is the "result/impact" raw material.
- `…/workplans/<feature>/tech-spec.md` — **what was built**: the components, the scope, the hard parts.
- `…/workplans/<feature>/tasks.md` and `NN-task.md` — the concrete deliverables; completed tasks map well to individual entries.
- `…/workplans/<feature>/implementation-notes.md` — decisions, tradeoffs, issues found, and verification notes — great for nuance and for honest "what was hard" framing.
- `…/pull-requests/<branch>.md` (if present) — the PR write-up, often with metrics and surface-area facts.

### Step 3: Add the evidence trail from git/PRs

The vault docs supply the *narrative*; git and `gh` supply the *evidence links and metrics*.

```bash
gh pr list --author @me --state merged --limit 20 --json number,title,repository,mergedAt
git log --author="$(git config user.email)" --since="<range>" --pretty=format:'%h|%ad|%s' --date=short --no-merges
```

Tie PRs/commits back to the feature (by branch name, scope, or title).

### Step 4: Draft impact-first entries

Convert the feature work into entries using the impact contract. Objectives/metrics from the PRD become the **result**; the PR/metric/commit becomes the **evidence**. Group related tasks/commits into one entry rather than one-per-task. **Never invent metrics the docs don't support** — if the PRD set a target but you can't confirm it was hit, ask the user or mark `(evidence needed)`.

### Step 5: Present, refine, save

Show the drafted entries first. After the user approves, append them to the brag document (tagged with this project). Report the vault path.

## Backfill workflow (mode B, no feature reference)

When the user asks "what did I do last week" or "backfill my history":

**Confirm the time range and scope first — don't assume "last week".** Then scan in order; don't draft entries until scanning is complete.

### Step 1: Scan available sources

```bash
git --version 2>/dev/null
gh --version 2>/dev/null
```

**Git commits** — recent commits by the user in the current repo:
```bash
git log --author="$(git config user.email)" --since="2 weeks ago" \
  --pretty=format:'%h|%ad|%s' --date=short --no-merges
```

**PR history** — merged PRs across repos (more reliable than commit logs for long ranges):
```bash
gh pr list --author @me --state merged --limit 20 \
  --json number,title,repository,mergedAt
```

**Vault feature docs** (unique to this suite) — the feature folders under `<vault>/engineering/<project>/workplans` are a record of substantial work. List them (`ls -1`) and, for features touched in the time range, pull context from their `prd.md` / `implementation-notes.md` as in mode A. This catches design and spec work that may not show up cleanly in git.

If none of these are available, fall back to the guided interview.

### Step 2: Group related work

- Same PR + its commits → 1 entry
- Multiple commits on the same file/feature within ~3 days → 1 entry
- A feature folder + its PR + its commits → 1 entry, framed from the PRD's impact

### Step 3: Draft, present, refine, save

Draft impact-first entries with categories, show them to the user, adjust, then append to the brag document grouped by week (under a project/week heading):

```markdown
## Week of 2026-04-14

### 🚀 PRs & Features
- **Migrated auth service to managed identity** → eliminated 3 secret-rotation incidents/quarter → PR #312

### 🏗️ Infrastructure
- **Built dispatch hot-path cache** → cut render-path DB reads ~60% → PR #126
```

## Guided interview (fallback)

When there's no feature reference and no git/PR traces (design work, incident response, mentoring), interview the user. For each accomplishment walk through: **What** (the deliverable) → **Why** (who benefited) → **Evidence** (PR, metric, link). Don't write entries for work described only verbally without verifying — ask: "Did this ship? Is there a PR or doc I can reference?"

## Performance review prep

When preparing for a review (annual, half, promo packet):

1. **Gather** entries from the work log (or backfill / feature-ground them first).
2. **Select** the top 3–5 highest-impact items.
3. **Rewrite** each with: what I did → why it mattered → proof (PR number, metric delta, dashboard, customer outcome).
4. **Organize by impact theme**, not chronologically: delivering results / operational excellence · customer & team impact · collaboration, mentoring, leadership · growth & learning.
5. **Ask for gaps** — "What metric changed?", "Who was unblocked?", "What's the PR or incident ID?"

For longer narrative sections, use **STAR**: Situation → Task → Action → Result. Append the synthesized result as a dated review section in the brag document.

## Agent behavior rules

1. **DO** confirm the time range and scope before scanning. Don't assume "last week".
2. **DO** decide mode A vs B up front (feature reference or not); ask if unclear.
3. **DO** always include all three parts: action → result → evidence. Mark `(evidence needed)` rather than omit.
4. **DO** show drafted entries to the user before saving. Never auto-save without confirmation.
5. **DO** group related commits/tasks into a single entry.
6. **DO** preserve the user's voice — reframe for impact, but never invent accomplishments or inflate scope.
7. **DO** append to the single brag document (preserve history); never overwrite it blindly.
8. **DO NOT** fabricate metrics, team sizes, or impact numbers. If the user/docs don't provide a number, keep it qualitative.
9. **DO NOT** pad weak periods with trivial entries — an honest gap beats inflated fluff.
10. **DO NOT** draft entries before scanning/reading is complete.

## Output contract

Before finishing, ensure:
1. Every entry has action → result → evidence (or `(evidence needed)`).
2. No fabricated metrics — only user-provided or source-verified data.
3. Entries were shown to the user before saving.
4. The time range (or feature) is explicitly stated.
5. Output is pasteable markdown with categories assigned, saved to the right vault path, and the path is reported.

## Gotchas

- **Work spans multiple repos.** Before concluding there's nothing to backfill, check `gh pr list --author @me --state merged` for cross-repo PRs and ask whether to scan another repo. Everything lands in the one `brag-document/brag-document.md`; tag each entry with its repo so cross-repo work stays navigable.
- **Review period doesn't match git history.** Reviews cover 6–12 months; set explicit `--since`/`--until`. PR history is more reliable than commit logs for long ranges.
- **Can't quantify impact.** Use the evidence ladder — PR links, "unblocked Team X", or qualitative outcomes with context are acceptable. Never invent a number.
- **PRD set a target but you can't confirm it shipped.** Don't claim the metric — ask the user or mark `(evidence needed)`.
- **Co-authored / pair work.** If multiple authors appear, ask: "Credit this as your work, shared work, or skip it?"
- **"brag" might mean a team announcement**, not a work entry. Confirm intent if ambiguous.
