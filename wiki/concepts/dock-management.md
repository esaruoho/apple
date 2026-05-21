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
bin/dock list                  # show every Dock item
bin/dock add  <path>           # folder / .savedSearch / file / .app
bin/dock add-spacer            # blank tile in persistent-others
bin/dock remove <path|label>   # match by path OR by displayed label
bin/dock clear-others          # nuke the entire right-side
```

After every write the script kills cfprefsd (twice — once to flush stale cache, once after write) and Dock. Change appears instantly.

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
