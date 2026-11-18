# Upstream skills

Four skills here are forks of `skills/engineering/` in https://github.com/mattpocock/skills. Each fork is the upstream text plus the deltas listed below; everything else matches upstream byte for byte.

| Local skill | Upstream skill | Synced at |
| --- | --- | --- |
| `ai-implement-ticket` | `implement` | `5863806` |
| `ai-to-tickets` | `to-tickets` | `5863806` |
| `ai-to-spec` | `to-spec` | `5863806` |
| `ai-setup-skills` | `setup-matt-pocock-skills` | `5863806` |

## Upgrade a fork

1. Clone upstream into a fresh temporary directory and note its `HEAD`.
2. Run `git log --oneline <synced-at>..HEAD -- skills/engineering/<upstream-skill>`. When it prints nothing, the fork is current; stop.
3. For `ai-implement-ticket`, `ai-to-tickets`, and `ai-to-spec`: copy upstream `SKILL.md` and `agents/openai.yaml` over the local files, then re-apply that skill's deltas below. Where an upstream change touches a delta's lines, keep the delta's intent and rewrite it against the new upstream text.
4. For `ai-setup-skills`: port each upstream change by hand, because its `SKILL.md` and tracker set differ by design. Copy upstream templates that have no delta.
5. Diff each fork against upstream `HEAD`. Done when every remaining difference is a listed delta. Update **Synced at** to the new `HEAD` and edit the deltas to match.

## Deltas

### All three single-file forks

- `name`: the local skill name.
- `/setup-matt-pocock-skills` becomes `/ai-setup-skills` everywhere.
- `agents/openai.yaml`: `display_name` is the local skill name. `ai-to-spec` has no `agents/` folder.

### `ai-implement-ticket`

- `description`: `"Implement, review, commit, and resolve exactly one tracker ticket. Use only when a prompt names ai-implement-ticket together with a ticket reference."` No `disable-model-invocation`, because `ai-implement` loads it.
- `"code-review"` becomes `"ai-code-review"`.
- `agents/openai.yaml`: `short_description` is `"Implement, review, and commit one ticket"`, and `allow_implicit_invocation` is `true`.

The skill relies on the `tdd` skill being installed.

### `ai-to-tickets`

- `description`: "small, focused tickets" instead of "a set of tracer-bullet tickets".
- Step 4 shows a **Project** line per ticket and asks whether each ticket has the right project, both marked Beads only.
- Step 5 has an **Obsidian** and a **Beads** publish entry before the real-tracker entry.

### `ai-to-spec`

Only the shared deltas.

### `ai-setup-skills`

- Domain docs stay out: upstream's Section C and the `CONTEXT.md` migration are dropped, because `domain-modeling` owns `GLOSSARY.md`, ADRs, and `docs/agents/domain.md`.
- Extra trackers: Obsidian, Workplan, and Beads, with their templates.
- `ticket-lifecycle.md` for Beads and Obsidian, and the `needs_human` Beads status that setup registers.
- The approval gate: setup shows the exact text and changes nothing before the user approves.
- The GitHub template's fork check omits the upstream repo name.
