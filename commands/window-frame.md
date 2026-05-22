---
description: Report on-screen window geometry vs. screen geometry (Apple-native CGWindowList + NSScreen). `/window-frame` lists every visible foreground window with x/y/w/h and what % of its parent screen's visibleFrame it occupies. `/window-frame <app>` filters to one app (case-insensitive substring). `/window-frame --json [<app>]` returns JSON. `/window-frame --screens` lists displays only. Used as the "report before mutating" pre-pass for `/snap`.
allowed-tools: Bash
argument-hint: [--json] [--screens] [<appname>]
---

Run the apple-skill `window-frame` helper on `$ARGUMENTS`.

Use Bash to execute (one call, then stop):

```
/Users/esaruoho/work/apple/bin/window-frame $ARGUMENTS
```

Modes:
- `/window-frame` — every visible foreground window across every display
- `/window-frame mail` — only Mail windows
- `/window-frame iterm2` — every iTerm2 window with current x/y/w/h + w%/h%
- `/window-frame --json` — JSON output (one `{screens: [...], windows: [...]}` object)
- `/window-frame --json safari` — JSON, filtered
- `/window-frame --screens` — list displays with frame + visibleFrame only

Coordinates are TOP-LEFT pixel space (matches `/snap` internals). `w%`/`h%` are window dimensions as a percentage of the parent screen's visibleFrame — useful for deciding whether `/snap` needs to run at all.

After the command completes, report only the lines it printed. Do not summarize.
