#!/usr/bin/env bash
#
# Emit a tab-separated import plan (SOURCE<TAB>VAULT_TARGET) for a legacy ai/ directory,
# normalizing names to the engineering/<project>/ Obsidian convention.
#
# Usage: plan-import.sh <ai-dir> <project>
#
# Mapping:
#   tasks/<feature>/<file>      -> engineering/<project>/<feature>/<file>
#   archive/<rel>               -> engineering/<project>/archive/<rel>
#   pull-requests/<file>        -> engineering/<project>/pull-requests/<file>
#   code-reviews/<rel>          -> engineering/<project>/code-reviews/review-<flattened>
#   codebase-review/<file>      -> engineering/<project>/codebase-reviews/<file>
#
# Name normalization (per path): lowercase, '_' -> '-', 'techspec' -> 'tech-spec'.
# commands/, templates/, docs/, plans/ are intentionally skipped (tooling / not content).

set -euo pipefail

ai_dir="${1:?usage: plan-import.sh <ai-dir> <project>}"
project="${2:?usage: plan-import.sh <ai-dir> <project>}"
base="engineering/$project"

norm() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | sed -e 's/_/-/g' -e 's/techspec/tech-spec/g'
}

emit() { printf '%s\t%s\n' "$1" "$2"; }

# tasks/<feature>/<file> -> <feature>/<file>
if [ -d "$ai_dir/tasks" ]; then
  find "$ai_dir/tasks" -type f -name '*.md' | while read -r f; do
    rel="${f#"$ai_dir"/tasks/}"
    emit "$f" "$base/$(norm "$rel")"
  done
fi

# archive/<rel> -> archive/<rel>  (preserves feature subfolders and loose docs)
if [ -d "$ai_dir/archive" ]; then
  find "$ai_dir/archive" -type f -name '*.md' | while read -r f; do
    rel="${f#"$ai_dir"/archive/}"
    emit "$f" "$base/archive/$(norm "$rel")"
  done
fi

# pull-requests/<file> -> pull-requests/<file>
if [ -d "$ai_dir/pull-requests" ]; then
  find "$ai_dir/pull-requests" -type f -name '*.md' | while read -r f; do
    emit "$f" "$base/pull-requests/$(norm "$(basename "$f")")"
  done
fi

# code-reviews/<rel> -> code-reviews/review-<flattened rel>
if [ -d "$ai_dir/code-reviews" ]; then
  find "$ai_dir/code-reviews" -type f -name '*.md' | while read -r f; do
    rel="${f#"$ai_dir"/code-reviews/}"
    flat="$(norm "$(printf '%s' "$rel" | tr '/' '-')")"
    case "$flat" in review-*) : ;; *) flat="review-$flat" ;; esac
    emit "$f" "$base/code-reviews/$flat"
  done
fi

# codebase-review/<file> -> codebase-reviews/<file>
if [ -d "$ai_dir/codebase-review" ]; then
  find "$ai_dir/codebase-review" -type f -name '*.md' | while read -r f; do
    emit "$f" "$base/codebase-reviews/$(norm "$(basename "$f")")"
  done
fi
