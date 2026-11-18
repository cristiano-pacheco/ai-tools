# Upstream

Fork of `skills/engineering/setup-matt-pocock-skills` in https://github.com/mattpocock/skills, synced at commit `5863806` (2026-11-18).

Synced: the GitHub and GitLab tracker templates, `triage-labels.md`, the reachable-repo check, and triage label creation on GitHub and GitLab. The GitHub template's fork check drops the upstream repo name.

Kept local on purpose:

- Domain docs: upstream's Section C and the `CONTEXT.md` migration stay out, because `domain-modeling` owns `GLOSSARY.md`, ADRs, and `docs/agents/domain.md`.
- Extra trackers: Obsidian, Workplan, Beads.
- `ticket-lifecycle.md` and the Beads lifecycle statuses.
- The approval gate: setup shows the exact text and changes nothing before the user approves.

To sync again, diff this folder against the upstream folder from `5863806` to its `HEAD`.
