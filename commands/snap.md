---
description: Tile windows into a non-uniform auto-sized grid. `/snap` = every visible foreground app, one cell per app. `/snap <appname>` = that app's windows tiled (case-insensitive substring match). `/snap <app> <screen>` targets a specific display. `/snap --screens` lists displays.
allowed-tools: Bash
argument-hint: [--passes N] [<appname>] [<screen|all>] | --screens
---

Run the apple-skill `snap` wrapper on `$ARGUMENTS`.

Use Bash to execute (one call, then stop):

```
/Users/esaruoho/work/apple/bin/snap $ARGUMENTS
```

Modes:
- `/snap` — tile every visible foreground app, one cell per app (every window of that app stacks in the cell)
- `/snap iterm2` — tile iTerm's 4 windows in a 2×2 grid on the main screen (uses iTerm's own AppleScript dictionary for stable window IDs)
- `/snap safari` — tile Safari's tabs/windows
- `/snap mail` — tile Mail windows (Mail enforces a min-width on its main window)
- `/snap iterm2 1` — tile on screen 1 (second display)
- `/snap subl all` — distribute Sublime windows round-robin across all screens
- `/snap --screens` — list available displays with index + visible-frame dimensions
- `/snap --show [<app>]` — report current window geometry without tiling (delegates to `/window-frame`; Goldilocks pre-pass)
- `/snap --passes 5 mail` — override the default 3-pass convergence loop

Grid is non-uniform row-based: n windows → `rows = round(sqrt(n))`, each row gets ceil/floor of `n/rows` cells. 5 → `3+2`, 7 → `4+3`, 11 → `4+4+3`. Every cell filled, no empty slots.

After the command completes, report only the lines it printed. Do not summarize results.
