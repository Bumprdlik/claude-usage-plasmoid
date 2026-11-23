# Claude Usage plasmoid

A KDE Plasma 6 panel widget that shows how much of your Claude plan you have used:
the current 5-hour session and the current week, each with a progress bar and the
time it resets.

## How it works

Claude Code passes a `rate_limits` object to its
[status line command](https://code.claude.com/docs/en/statusline) on every reply
(Pro, Max and Ultra plans only). `claude-statusline` is that command: it prints a
short status line and saves `rate_limits` to `~/.cache/claude-usage.json`.
The widget reads that file every 15 seconds.

So the numbers are only as fresh as your last Claude Code reply. Usage on claude.ai
or in Claude Desktop counts toward the same limits, but shows up here only after the
next reply in Claude Code. The widget greys out when its data is over an hour old,
and a window past its reset time is shown as 0%.

No tokens or credentials are read; nothing is sent anywhere.

## Install

Needs `jq` and Plasma 6.

```sh
./install.sh
```

It symlinks `package/` to `~/.local/share/plasma/plasmoids/org.local.claudeusage`
and `claude-statusline` to `~/.local/bin/`. Then add to `~/.claude/settings.json`:

```json
"statusLine": { "type": "command", "command": "~/.local/bin/claude-statusline" }
```

and add **Claude Usage** to a panel (right-click the panel → Add or Manage Widgets).

In a vertical panel the widget takes the full panel width; click it for details.
Bar colour follows the theme's highlight colour, turning orange at 80% and red at 95%.

## Files

- `claude-statusline` — Claude Code status line script (bash + jq)
- `package/` — the Plasma applet (`metadata.json`, `contents/ui/main.qml`)
- `install.sh` — symlinks both into place
