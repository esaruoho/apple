---
description: The spatial overlay — a click-through canvas floating over every window that both you and agents can draw on. `/overlay` shows status; `/overlay open` launches it (⌃⌥⌘D toggles draw mode, esc leaves); `/overlay post <kind> --rel X,Y,W,H` puts an arrow / box / highlight / spotlight / label / callout / sticker on the screen from an agent; `/overlay clear [--actor A]` removes marks. Apple-native AppKit, no permissions required.
allowed-tools: Bash
argument-hint: [open|status|post|clear|draw|dump|kinds|quit] [...]
---

Run the apple-skill `overlay` helper on `$ARGUMENTS`.

Use Bash to execute (one call, then stop):

```
/Users/esaruoho/work/apple/bin/overlay $ARGUMENTS
```

Modes:
- `/overlay` — status: running? how many marks, by which actor?
- `/overlay open` — launch Overlay.app (menu-bar only; ⌃⌥⌘D draws, esc leaves)
- `/overlay kinds` — the object vocabulary an agent can post
- `/overlay post box --rel 0.1,0.2,0.3,0.1 --actor agent:fm --ttl ephemeral`
- `/overlay post callout --rel 0.5,0.5,0.1,0.1 --text "this is the stuck process"`
- `/overlay post spotlight --rel 0.3,0.3,0.4,0.3` — dim everything else
- `/overlay post --stdin` — read one object, or an array, as JSON
- `/overlay clear --actor agent:fm` — remove one agent's marks, leave the human's ink
- `/overlay dump --json` — the marks currently mirrored to disk

`--rel` is 0…1 of the screen (preferred: an agent needs to know nothing about pixel
sizes); `--rect X,Y,W,H` and `--at X,Y` take absolute AppKit coordinates, origin
bottom-left. Posted objects default to `ttl: session` so an agent cannot litter the
desktop permanently.

Posting never enters draw mode — the overlay stays click-through while marks are up.

After the command completes, report only the lines it printed. Do not summarize.
