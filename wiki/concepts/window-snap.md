# Window Snap — Tile Any App's Windows Into An Auto-Sized Grid

Standalone window-tiling engine. Same binary called from terminal, `/snap` slash, AppleToolbox menu, and `dock snap` (which now delegates here).

## CLI

```bash
snap                        # tile every visible foreground app, one cell per app
snap iterm2                 # tile iTerm's windows on main screen
snap iterm2 0               # …explicit screen 0 (main)
snap iterm2 1               # …on screen 1 (second display)
snap subl all               # distribute Sublime windows round-robin across all screens
snap --screens              # list available displays
snap --passes 5 mail        # override default 3-pass convergence loop
```

## Files

| Path | Role |
|---|---|
| `bin/snap` | bash wrapper. Parses `--passes`, `--screens`, `--show`, runs the AppleScript N times |
| `bin/window-frame` | Apple-native CGWindowList + NSScreen reporter. Powers `snap --show` and `/window-frame`. Goldilocks pre-pass: "how big is this app right now vs. the screen?" |
| `scripts/workflows/system-events/tile-dock-snap.applescript` | engine — grid math + per-app dispatch |
| `scripts/workflows/system-events/compiled/tile-dock-snap.scpt` | compiled engine `bin/snap` calls |
| `commands/snap.md` | `/snap` slash dispatcher |
| `commands/window-frame.md` | `/window-frame` slash (pre-pass: report current geometry without mutating) |
| `bin/dock` `cmd_snap()` | thin shim that delegates `dock snap` to `bin/snap` |
| `topbar/AppleToolbox.swift` | menu entries that shell out to `bin/snap` |

## Pre-pass: see before you snap

`snap --show [<app>]` (or `/window-frame [<app>]`) dumps each visible window's `pid / layer / owner / title / screen / x / y / w / h / w% / h%` where the percentages are against the parent screen's `visibleFrame`. Coordinates are TOP-LEFT pixel space (same as tile-dock-snap internals). Use this to decide whether a `snap` is needed at all and to verify post-tile geometry. `--json` returns `{screens: [...], windows: [...]}` for programmatic callers (AppleToolbox, future agent loops).

## Grid algorithm

Non-uniform row-based layout: `rows = round(sqrt(n))`, each row gets ceil/floor of `n / rows` cells.

| Windows | Layout |
|---|---|
| 1 | 1 |
| 2 | 2 |
| 3 | 3 |
| 4 | 2+2 |
| 5 | 3+2 |
| 6 | 3+3 |
| 7 | 3+2+2 |
| 9 | 3+3+3 |
| 11 | 4+4+3 |

Every cell filled, no empty slots. Two-pass `set size` + `set position` per cell (Safari auto-adjust workaround).

## Per-app dispatcher

```
process name → AppleScript app name
─────────────────────────────────────
iTerm2 / iTerm     → "iTerm"
Safari             → "Safari"
Mail               → "Mail"
Terminal           → "Terminal"
Finder             → "Finder"
Sublime Text       → "Sublime Text"  (needs TCC permission)
Google Chrome      → "Google Chrome" (needs TCC permission)
TextEdit / Music / Notes / Preview → same name
```

For apps in this table, `tileWithAppDict(appName, …)` builds a single multi-line `tell application "X" … end tell` AppleScript at runtime (via `run script`), inlining every `set bounds of (first window whose id is N) to {…}` call. One round trip, runs reliably in one pass because stable window IDs survive position changes.

For apps NOT in the table, falls back to System Events `set position` / `set size` per window. Convergence loop (3 passes by default) coaxes apps that fight back.

## Why per-app dispatch

System Events `windows of process` returns POSITIONAL references that resolve LAZILY. When we `set position of window 1`, the app may reorder its window list. The next iteration's "window 2" is no longer the same window as before — and `contents of w` does NOT freeze the reference; it just dereferences once. Two windows end up in the same cell, one cell stays empty.

The only stable identifier across `set position` calls is the app's own `id of window` from its AppleScript dictionary. That's why we use `tell application "X"` directly for known-scriptable apps.

## Multi-screen

`snap --screens` lists displays via `NSScreen.screens` with index + visibleFrame.

`snap <app> <N>` targets `NSScreen.screens[N]`. The Swift one-liner converts to top-left coordinates using the total bounding height across all screens (handles negative Y for displays above main).

`snap <app> all` partitions windows round-robin (window 1 → screen 0, window 2 → screen 1, window 3 → screen 0, …), then tiles per-screen.

## Adding an app

1. Verify it has a scriptable dictionary with stable IDs:
   ```bash
   osascript -e 'tell application "<X>" to return id of every window'
   ```
   If it returns integers, it's eligible. If it errors with "Not authorized", grant TCC permission first (System Settings → Privacy & Security → Automation).

2. Add one line to `appNameForProcess` in `tile-dock-snap.applescript`:
   ```applescript
   if procName is "<ProcessName>" then return "<AppleScriptName>"
   ```
   (Often they match, e.g. `"Safari"`. iTerm is the exception: process name `iTerm2`, AppleScript name `iTerm`.)

3. Recompile: `osacompile -o scripts/workflows/system-events/compiled/tile-dock-snap.scpt scripts/workflows/system-events/tile-dock-snap.applescript`

4. Test: `snap <appname>`.

## Trigger words for future Claude sessions

`snap` · `dock snap` · "tile windows" · "arrange windows" · "windows in a grid" · "side by side all" · "mosaic apps" · "snap windows" · "multi-screen tile" · "distribute across screens"

→ this page is the entry point. Don't reinvent.
