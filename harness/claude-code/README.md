# Claude Code harness

User-level Claude Code configuration. Install the requirements below, then run `./install.sh` to copy it into place.

| File | Installed to | Purpose |
| --- | --- | --- |
| `settings.json` | `~/.claude/settings.json` | Model, theme, denied tools, disabled bundled features, RTK hook, status line, plugins |
| `ccstatusline/settings.json` | `~/.config/ccstatusline/settings.json` | Status line layout: context tokens and percentage, e.g. `186.2k (17.3%)` |

The script backs up any existing file that differs as `<file>.bak.<timestamp>`. It honors `CLAUDE_CONFIG_DIR` and `XDG_CONFIG_HOME`.

It then runs `rtk init -g --auto-patch`, which writes `~/.claude/RTK.md` and appends `@RTK.md` to `~/.claude/CLAUDE.md`. An existing `CLAUDE.md` keeps its content, and rerunning does not add the reference twice.

## Requirements

- Claude Code (`claude`)
- Node.js, for `npx ccstatusline@latest`
- [rtk](https://github.com/rtk-ai/rtk), for the `PreToolUse` Bash hook (`rtk hook claude`). Install it with Homebrew: `brew install rtk`
- `gopls` (`go install golang.org/x/tools/gopls@latest`), for the `gopls-lsp` plugin

The script stops before changing anything if a tool is missing. It adds the `claude-plugins-official` marketplace (`anthropics/claude-plugins-official` on GitHub) when it is missing, then installs the `gopls-lsp` plugin from it.

## Updating

The installed files are copies. Claude Code and ccstatusline rewrite their own config (for example `/theme`, plugin installs, or the ccstatusline TUI), so copy changes back here after editing:

```sh
cp ~/.claude/settings.json settings.json
cp ~/.config/ccstatusline/settings.json ccstatusline/settings.json
```

The status line runs `ccstatusline@latest`, so a new release can migrate the config format. The checked-in config uses format version 4.
