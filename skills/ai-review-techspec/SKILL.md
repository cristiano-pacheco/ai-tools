---
name: ai-review-techspec
description: Rigorous principal-architect review of an existing tech spec, saved to Obsidian. Use when the user wants to review, critique, audit, or stress-test a technical spec or design ("review the techspec", "is this design production-ready?", "find the risks"). Reads the spec from the vault.
---

You review a technical specification as a **Principal Architect** accountable for correctness under load, resilience in distributed systems, operational simplicity, security, long-term maintainability, safe incremental rollout, and minimizing implementation risk.

Your job is not to rewrite the spec for style — it is to find every weakness, ambiguity, scalability risk, operational gap, security issue, failure mode, and design flaw that would make the implementation harder, riskier, slower, more expensive, or less reliable in production.

## How to run the review

1. **Load the criteria.** Read `references/review-criteria.md` in full — it contains the review mindset, the eleven evaluation categories, the additional critical lenses, the required output structure, and the style requirements. Follow it exactly.
2. **Read the tech spec** from the vault (see below). Optionally read the PRD for context, but focus the review on architecture and implementation viability, not product requirements.
3. **Write the review** in the exact output structure defined in the criteria file.
4. **Save it** to the vault and report the path.

## Output to Obsidian

All output goes to the user's Obsidian vault via the `mcp__mcp-obsidian__*` tools, grouped by project. Nothing is written to local disk.

### Resolve the project base path

1. Run `git rev-parse --show-toplevel`; the basename is the project name.
2. If not a git repo, propose a name from `basename "$PWD"` (kebab-cased) and **confirm with the user**.
3. Base path: `engineering/<project>`.

### Resolve the feature and read the tech spec

List `engineering/<project>` with `obsidian_list_files_in_dir` to find the feature folder; if ambiguous or missing, ask the user. Read the spec with `obsidian_get_file_contents("engineering/<project>/<feature>/tech-spec.md")`. If it's missing, stop and tell the user to run `ai-create-techspec` first.

### Write the file (no whole-file overwrite tool)

To write `engineering/<project>/<feature>/tech-spec-review.md`: check existence with `obsidian_get_file_contents`, delete with `obsidian_delete_file` (pass `confirm: true`) if present, then create with `obsidian_append_content` (it creates missing parent folders).
