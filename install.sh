#!/usr/bin/env bash
# Links the widget and the status line script from this repo into place,
# so edits here take effect without reinstalling.
set -euo pipefail

repo=$(cd "$(dirname "$0")" && pwd)
plasmoids="${XDG_DATA_HOME:-$HOME/.local/share}/plasma/plasmoids"
bin="$HOME/.local/bin"

mkdir -p "$plasmoids" "$bin"
ln -sfn "$repo/package" "$plasmoids/org.local.claudeusage"
ln -sfn "$repo/claude-statusline" "$bin/claude-statusline"

echo "Installed. Now:"
echo "  1. Add to ~/.claude/settings.json:"
echo '     "statusLine": { "type": "command", "command": "~/.local/bin/claude-statusline" }'
echo "  2. Right-click a panel → Add or Manage Widgets → \"Claude Usage\"."
echo "  After editing main.qml: systemctl --user restart plasma-plasmashell"
