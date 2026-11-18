#!/usr/bin/env bash
# Install the Claude Code harness config from this directory.
# Existing files that differ are backed up as <file>.bak.<timestamp>.
set -euo pipefail

src="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
claude_dir="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
ccstatusline_dir="${XDG_CONFIG_HOME:-$HOME/.config}/ccstatusline"
stamp="$(date +%Y%m%d%H%M%S)"

missing=0
for cmd in claude npx rtk gopls; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    case "$cmd" in
      rtk) echo "missing: rtk (install with: brew install rtk)" >&2 ;;
      *) echo "missing: $cmd" >&2 ;;
    esac
    missing=1
  fi
done
if [[ $missing -eq 1 ]]; then
  echo "Install the missing tools listed in README.md, then rerun this script." >&2
  exit 1
fi

# JSON files match when their content is equal, ignoring key order and
# formatting, because Claude Code rewrites settings.json in its own order.
same_content() {
  if [[ "$1" == *.json ]] && command -v jq >/dev/null 2>&1; then
    cmp -s <(jq -S . "$1" 2>/dev/null) <(jq -S . "$2" 2>/dev/null)
  else
    cmp -s "$1" "$2"
  fi
}

install_file() {
  local from="$1" to="$2"
  mkdir -p "$(dirname "$to")"
  if [[ -e "$to" ]]; then
    if same_content "$from" "$to"; then
      echo "unchanged  $to"
      return
    fi
    cp "$to" "$to.bak.$stamp"
    echo "backed up  $to -> $to.bak.$stamp"
  fi
  cp "$from" "$to"
  echo "installed  $to"
}

install_file "$src/settings.json" "$claude_dir/settings.json"
install_file "$src/ccstatusline/settings.json" "$ccstatusline_dir/settings.json"

# Writes ~/.claude/RTK.md and appends @RTK.md to ~/.claude/CLAUDE.md,
# keeping any existing content. The hook is already in settings.json.
rtk init -g --auto-patch

if ! claude plugin marketplace list 2>/dev/null | grep -q 'claude-plugins-official'; then
  claude plugin marketplace add anthropics/claude-plugins-official
fi
claude plugin install gopls-lsp@claude-plugins-official --scope user \
  || echo "warning: could not install gopls-lsp plugin" >&2

echo "Done. Restart Claude Code to load the new settings."
