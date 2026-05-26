# iMessage from Terminal — Text + File Attachments

Single CLI: `imessage`. Sends text or files via iMessage to any buddy.
Default buddy = `esaruoho@gmail.com`. Source: `bin/imessage`. Slash: `/imessage`.

```bash
imessage "yo yo yo hi hi hi"                   # text
imessage file.pdf                              # attachment (auto-detected)
imessage --text "see attached" file.pdf        # text + file (separate bubbles)
imessage --to +358401234567 "hello"            # different buddy
IMESSAGE_TO=other@apple.id imessage file.zip   # default via env
```

## Why text and files take different paths

**Text:** the Messages AppleScript dictionary's `send "..." to buddy` works
correctly on every macOS, returns reliably, and shows the bubble. This is
the path we use for text.

**Files:** the equivalent `send (POSIX file "...") to buddy` returns success
(`exit 0`) on macOS Sequoia but the attachment never renders in the
conversation. This is a regression. Both common dialects
(`buddy "..." of service whose service type = iMessage` and the newer
`participant "..." of account id ...`) are silently broken.

The only path that actually attaches the file on Sequoia:

1. **Put the file on the macOS pasteboard as a file reference, not text.**
   ```applescript
   tell application "Finder" to set the clipboard to
       (POSIX file "/abs/path") as alias
   ```
   This writes an `alias`-typed clipboard entry — the same type Finder puts
   on the clipboard when you Cmd-C a file in the Finder window.

2. **Open the buddy's conversation.**
   ```bash
   open "imessage://esaruoho@gmail.com"
   ```
   The `imessage://` URL scheme jumps Messages directly to that thread,
   regardless of where it was before. Bring-to-foreground happens
   automatically.

3. **UI-script Cmd-V then Return via System Events.**
   ```applescript
   with timeout of 10 seconds
     tell application "System Events"
       keystroke "v" using command down
       delay 0.6
       key code 36          -- Return
     end tell
   end timeout
   ```
   Note: keystroke into the **frontmost** target (not `tell process "Messages"`).
   Messages on Sequoia doesn't always expose its AX tree quickly, so
   `tell process "Messages"` can time out with `-1712` even when Messages
   is actually responsive. WindowServer-level keystroke routing is the
   reliable form.

## "Not Delivered" red ! — usually transient, not a real failure

Attachments to your own Apple ID sometimes show a brief red "Not Delivered" !
right after sending. It typically clears within a few seconds and the file
lands as iMessage on the other devices.

Do **not** "fix" this by switching the default recipient to your own phone
number. Phone-number routing falls back to SMS/MMS (green bubble, ~1 MB cap,
lossy compression for media). For screenshots and most files, that is the
wrong outcome — keep the email default and let the transient ! clear.

If a specific send is genuinely stuck (red ! persists for >30 s and the
phone never receives it), the right escalation is **AirDrop**, not SMS —
AirDrop between devices on the same Apple ID auto-accepts, is lossless, and
doesn't go through any servers.

## First-run TCC prompt

The first time `imessage <file>` runs, macOS prompts:
*"Terminal would like to control 'System Events'."*
Accept it. System Settings → Privacy & Security → Accessibility → ensure
the terminal app (Terminal, iTerm2, whatever) is listed and toggled on.
Subsequent invocations are silent.

This is the same TCC grant covered by `/grant-perms`. If `/grant-perms` was
already run, `imessage` works on the first call.

## Gotchas

- **`with timeout` is mandatory.** Without it, a Messages modal (e.g. "Send
  to non-iMessage number?") or a stuck System Events daemon will hang
  osascript forever. The CLI wraps the UI-script block in `with timeout of
  10 seconds` and also wraps the subprocess call in a 15 s Python timeout.
- **System Events can wedge.** Symptom: `keystroke ""` itself times out with
  AppleEvent -1712. Fix: `killall "System Events"` to respawn its daemon.
  This is rare but worth knowing.
- **Don't enumerate Messages's UI.** `tell process "Messages" to get every
  window` hangs reliably during attachment uploads. Keystroke routing via
  the frontmost target avoids this entirely.
- **Don't `tell application "Messages" to activate`.** During a previous
  send's upload, this hangs at the Apple Event layer. The `open
  imessage://...` URL handler handles focus without going through Messages's
  AE handler.
- **Open the chat each send.** Even if the buddy's thread was already
  visible, re-`open imessage://...` to guarantee correct routing — Messages
  sometimes auto-switches to a different thread on incoming activity.
- **The clipboard contains an alias.** Anything you Cmd-V into anywhere
  afterward will paste the file. The next time you copy text the clipboard
  is restored, but if you want to be paranoid you can `pbcopy < /dev/null`
  after the send.
- **Multiple files:** call `imessage` once per file. The clipboard only
  holds one alias at a time.

## Used by

- `bin/imessage` — the CLI itself
- `bin/build-notify-iphone-shortcut.py` — its installer instructions point
  the user at `imessage` for delivery to the phone
- Anywhere you want to push a file to your iPhone without iCloud sync delay
  (iMessage push is sub-second; iCloud Drive is 2-15 s)

## See also

- `wiki/concepts/iphone-notify-pipeline.md` — the iCloud-Drive-based notify
  channel (no urgency push, but doesn't generate a Messages bubble)
- `wiki/concepts/clipboard-rich-text.md` — sibling skill for putting
  rich text (vs. a file reference) on the clipboard
- `wiki/entities/appletoolbox.md` — the menu-bar host (could grow a "Send
  to Phone" submenu around `imessage` if useful)
