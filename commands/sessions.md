---
description: TUI session picker for Claude Code. Lists sessions for a folder, ⏎ resumes with --dangerously-skip-permissions. Opens in iTerm. Usage `/sessions [folder]` (default current project).
allowed-tools: Bash
argument-hint: [folder-path]
---

Open the `sessions` TUI in iTerm so the user can pick a Claude Code session to resume for `$ARGUMENTS` (default: `~/work/apple`).

Use Bash (one call, then stop):

```
FOLDER="${ARGUMENTS:-$HOME/work/apple}"
[ -z "$FOLDER" ] && FOLDER="$HOME/work/apple"
case "$FOLDER" in ~*) FOLDER="${HOME}${FOLDER#\~}" ;; esac
CMD="cd \"$FOLDER\" && /Users/esaruoho/work/apple/bin/sessions"
/usr/bin/osascript -e "tell application \"iTerm\"
    activate
    create window with default profile
    tell current session of current window to write text \"$CMD\"
end tell"
echo "opened sessions picker in iTerm for $FOLDER"
```

Notes:
- Picker shows newest-first list with ↑/↓ + first-user-message snippet.
- ⏎ resumes that session via `claude --dangerously-skip-permissions --resume <uuid>`.
- `n` starts a fresh `claude --dangerously-skip-permissions` in that folder.
- `q` / Esc quits.
- The TUI itself runs in iTerm because curses needs a real TTY. Bash tool just hands it off.

After the osascript call, report only the path the picker was opened on. Do not re-run.
