# Dock Management — Apple-Native Add/Remove/List

Built 2026-05-21, replacing the dead `LSSharedFileList` sidebar path.

## Why

Apple removed both the public API and the menu item for "Add to Sidebar" in Sequoia. The Dock is the surviving Apple-blessed pin surface — and unlike the sidebar, the Dock's plist `~/Library/Preferences/com.apple.dock.plist` is still writable from userland with plistlib + a `killall cfprefsd Dock`.

## The plist shape

Two arrays matter:

- `persistent-apps` — left side of the Dock (apps)
- `persistent-others` — right side (folders, files, spacers)

Each entry is a dict:

```python
{
  "tile-data": {
    "file-data": {
      "_CFURLString": "file:///Users/esaruoho/Library/Saved%20Searches/All%20Smart%20Folders.savedSearch",
      "_CFURLStringType": 15,    # 15 = file URL string
    },
    "file-label": "All Smart Folders",
    "file-type": 2,              # 2 = folder/dir, 32 = file, 41 = app
  },
  "tile-type": "directory-tile",  # or "file-tile", "spacer-tile"
}
```

`.savedSearch` files get `directory-tile` even though they're technically files — Dock then renders them as a Smart-Folder stack.

## CLI

```
dock list                              # show every Dock item
dock add  <path>                       # folder / .savedSearch / file / .app
dock add-spacer                        # blank tile in persistent-others
dock remove <path|label>               # match by path OR by displayed label
dock clear-others                      # nuke the entire right-side

dock screens                           # list available displays with index
dock snap                              # tile every running app, one cell per app
dock snap <appname>                    # tile <appname>'s windows in a grid
dock snap <appname> <screenIdx>        # …on a specific screen (0=main, 1=second, …)
dock snap <appname> all                # distribute round-robin across all screens
dock snap --passes N <args…>           # override 3-pass convergence
```

After every Dock write the script kills cfprefsd (twice — once to flush stale cache, once after write) and Dock. Change appears instantly.

## Window tiling — `dock snap`

Non-uniform row-based grid: `rows = round(sqrt(n))`, cells per row = ceil/floor of `n/rows`. Every cell fills, no empty slots. Examples: 5 → `3+2`, 7 → `4+3`, 11 → `4+4+3`.

**Two execution paths, dispatched by process name:**

1. **App-native (preferred)** — for apps whose AppleScript dictionary exposes stable `id of window`. Currently: iTerm/iTerm2. `tell application "iTerm" to set bounds of (first window whose id is wid)`. Reliable, no convergence loop needed.

2. **System Events fallback** — for everything else. Reads `windows of process` and sets position/size per window. **Known broken** in the general case because System Events' window references are POSITIONAL and resolve lazily — when you set position on window 1, the app reorders, and the next iteration's "window 2" hits what was window 1. The Python wrapper retries 3 times with 250 ms gaps to coax convergence; some apps settle, some still leave duplicates.

**To add another app's stable-ID path:**

1. Confirm `osascript -e 'tell application "X" to id of every window'` returns integers
2. In `tile-dock-snap.applescript`, add a branch in `tileOneApp` matching the process name
3. Write a `tileWithX` handler mirroring `tileWithITerm` — compute the grid layout from `winIds`, set bounds via the app's dictionary

Process names worth checking next: Safari, Mail, Finder, Sublime Text. Each likely has stable IDs but needs the per-app handler.

## Multi-screen

`dock screens` lists displays via NSScreen.screens with index, localizedName, and visibleFrame.

`dock snap <app> <N>` targets a specific screen. The Swift one-liner picks `NSScreen.screens[N].visibleFrame` and converts to AppleScript's top-left coordinates using the total bounding height across all screens (handles negative Y for displays positioned above main).

`dock snap <app> all` partitions the app's windows round-robin: window 1 → screen 0, window 2 → screen 1, window 3 → screen 0, … then tiles per-screen using the same row-layout logic.

## Slash + AppleToolbox

- `/dock <subcommand>` — slash dispatcher to `bin/dock`
- AppleToolbox menu: `🧰 → 🏷 Tags → 📌 Pin All Smart Folders to Dock` one-click pin

## Replaces

- The dead `bin/sidebar-add.swift` attempt (LSSharedFileList segfaults on Sequoia)
- The manual "drag to sidebar" workflow that doesn't accept .savedSearch files

## Discoverability triggers

When the user says any of:
- "add to dock" / "pin to dock"
- "dock item" / "dock tile" / "dock spacer"
- "add smart folder to dock" / "pin smart folder"

→ this page is the entry point. Don't reinvent.
