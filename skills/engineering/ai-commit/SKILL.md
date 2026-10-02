---
name: ai-commit
description: Commit and push vault artifacts or explicitly scoped code changes.
disable-model-invocation: true
---

This skill owns vault Git operations for the `ai-*` suite. Other skills delegate vault staging, commits, and pushes here. The default target is `vault`; only `ai-review-and-fix` may request `code`.

## Inputs

- `target` is `vault` by default, or `code`.
- `message` is optional. Prefer the caller's Conventional Commit message; otherwise compose one from the staged diff.
- `code paths` is required for `code`. The caller must inspect `git status --short` and supply exact repository-relative paths it changed, excluding unrelated work.

## Resolve repositories

1. Set `V="${OBSIDIAN_AI_VAULT:-$HOME/Documents/obsidian/obsidian}"`. Verify the directory exists and is a Git repository. On failure, stop and tell the user to run `ai-setup` or set `OBSIDIAN_AI_VAULT`.
2. Resolve `VAULT_TOPLEVEL` with `git -C "$V" rev-parse --show-toplevel` and `CWD_TOPLEVEL` with `git rev-parse --show-toplevel`. The code target requires the latter to succeed.
3. If the toplevels match, abort. The caller must run from the code repository, not the vault.

## Stage and commit

Use only the selected repository. For `vault`, run every Git command with `git -C "$V"`. For `code`, use `git -C "$CWD_TOPLEVEL"`.

### Vault target

1. Run `git -C "$V" add -A`. This includes unrelated vault changes, preserving the suite's existing behavior. Callers should invoke this skill immediately after writing their artifacts.
2. Inspect `git -C "$V" diff --cached`. If empty, report that the vault is up to date and stop.
3. Commit with `git -C "$V" commit -m "<message>"`.

### Code target

1. Require a non-empty `code paths` list. Reject absolute paths, `..` traversal, and any path that resolves outside `CWD_TOPLEVEL`.
2. Stage only those paths with `git -C "$CWD_TOPLEVEL" add -- <paths>`.
3. Inspect the staged diff restricted to those paths. If empty, report that no code commit is needed and stop.
4. Commit only those paths with `git -C "$CWD_TOPLEVEL" commit --only -m "<message>" -- <paths>`. Leave unrelated staged changes untouched.

Use `<type>(<optional scope>): <description>`, omitting parentheses when there is no scope. Write a lowercase, imperative description with no final period. Preserve body line breaks and omit `Co-Authored-By` trailers.

If a commit fails, report the exact error and stop for the user to resolve it. Create new commits only; never amend or rewrite history.

## Push and report

After a successful commit, push the current branch if the selected repository has `origin`. Never force-push. A missing origin or failed push is non-fatal; report the outcome and keep the local commit. `ai-setup` configures the vault remote.

Report the commit hash and whether the push succeeded, failed, or was skipped. If a repository guard stopped the workflow, report that reason instead.
