---
layout: default
title: "Finder Sidebar Favorites — Programmatic Editing Is Dead on Sequoia"
---

# Finder Sidebar Favorites — Programmatic Editing Is Dead on Sequoia


[← Back to home](./)
Tested 2026-05-21 on macOS Sequoia. **Do not attempt to programmatically add items to Finder's sidebar Favorites via `LSSharedFileList`.** It is gone.

## What used to work

`LSSharedFileList` (CoreServices) — list / insert / remove sidebar Favorites. Deprecated by Apple in macOS 10.11 (2015) but functional through Big Sur and Monterey. Used by `mysides`, Alfred, LaunchBar, etc.

## What happens now on Sequoia

```swift
LSSharedFileListCopySnapshot(list, &seed)?.takeRetainedValue() as? [LSSharedFileListItem]
// → empty array. The public API returns nothing.

LSSharedFileListInsertItemURL(list, kLSSharedFileListItemLast.takeUnretainedValue(),
                              nil, nil, url as CFURL, nil, nil)
// → SIGSEGV. Process dies.
```

Apple's documentation says "deprecated"; reality on Sequoia is "amputated."

## What the data structure actually looks like

`~/Library/Application Support/com.apple.sharedfilelist/com.apple.LSSharedFileList.FavoriteItems.sfl3`

It's an `NSKeyedArchiver` archive (binary plist) containing `SFLListItem` objects with bookmark-data blobs. You CAN edit it from Python via `plistlib` if you decode the keyed-archive structure — but `sharedfilelistd` caches the in-memory copy aggressively, and Finder restarts won't always pick up changes. Brittle.

## The working alternatives, ranked

### 1. Drag manually (Apple-blessed, always works)

Open Finder → `Cmd-Shift-G` → `~/Library/Saved Searches/` → drag the `.savedSearch` onto Finder's Favorites in any Finder window's sidebar. Done forever.

For "All Smart Folders.savedSearch" specifically: drag it once and every Smart Folder you ever create is one click away (it lists `~/Library/Saved Searches/` contents live).

### 2. AppleScript UI automation against Finder (fragile but native)

```applescript
tell application "Finder"
    activate
    open POSIX file "/path/to/folder"
end tell
tell application "System Events"
    tell process "Finder"
        -- Drag the source row from the file list to the Favorites section
        -- of the sidebar. Coordinates are window-relative and brittle.
    end tell
end tell
```

Works but every macOS Finder layout change breaks the coordinates. Don't ship.

### 3. AppleToolbox "🗂 Smart Folders ▸" submenu (what we built)

Already there. `🧰 → 🏷 Tags → 🗂 Smart Folders ▸` enumerates every `.savedSearch` at menu-open time. **One click instead of one drag.** Solves the discoverability problem without touching Finder's sidebar at all.

## Conclusion

For sidebar Favorites: drag once.

For one-click access to Smart Folders without using the sidebar: AppleToolbox already covers it.

For future Claude sessions tempted to write `bin/sidebar-add.swift`: don't. The previous attempt segfaulted. Path was deleted on commit `1d02e1b` follow-up.
