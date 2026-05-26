---
description: Send iMessage text or file attachments from the terminal. Default buddy = esaruoho@gmail.com (override with --to or $IMESSAGE_TO). Files attach via clipboard + UI-script — the only path that actually works on Sequoia (the AppleScript dictionary's `send file` silently no-ops). Usage `/imessage <text-or-file>` or `/imessage --to <buddy> <text-or-file>`.
allowed-tools: Bash
argument-hint: <text-or-file> [--to <buddy>] [--text "..."] [--file <path>]
---

# /imessage

Send an iMessage to yourself (or anyone) from the terminal — text or files.

```bash
/imessage "yo yo yo hi hi hi"
/imessage file.pdf
/imessage --text "see attached" file.pdf
/imessage --to +358401234567 "hello"
/imessage --to other@apple.id ~/Downloads/foo.shortcut
```

## Detection

- If the positional argument is an existing file path → attach as file.
- Otherwise → send as text.
- Use `--text` or `--file` to force a mode explicitly.

## Why files need a different path than text

`tell application "Messages" to send (POSIX file "...") to buddy ...` reliably no-ops on macOS Sequoia (the call succeeds but no attachment renders). The only working path is:

1. Set the macOS clipboard to a file reference via Finder
2. `open imessage://<buddy>` to focus that thread
3. UI-script Cmd-V then Return via System Events

The CLI does all three transparently.

## First-run setup

The first `imessage <file>` invocation triggers an Accessibility TCC prompt for the terminal app (Terminal, iTerm, or whatever your shell runs in). Accept it once — System Settings → Privacy & Security → Accessibility → add the terminal app. Subsequent calls are silent.

## Default buddy

`esaruoho@gmail.com`. Override per-call with `--to`, or set `IMESSAGE_TO` in your shell profile.

## Troubleshooting

- **"UI-script paste failed: AppleEvent timed out"** — System Events is wedged. `killall "System Events"` to restart its daemon, retry.
- **File "sent" but no attachment** — Messages's own Apple-Event handler was busy. Wait a few seconds and retry; the script has a `with timeout` guard so it won't hang forever.
- **Text-only sends fine, files fail** — Accessibility permission missing for the terminal app.

Source: `bin/imessage`. See also: `wiki/concepts/imessage-from-terminal.md`.
