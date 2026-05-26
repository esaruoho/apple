---
layout: default
title: "Finder Toolbar — Shortcuts.app Quick Actions DO NOT Appear in Customize Toolbar"
---

# Finder Toolbar — Shortcuts.app Quick Actions DO NOT Appear in Customize Toolbar



[← Back to home](./)
Tested 2026-05-26 on macOS Sequoia.

**Finder's `View → Customize Toolbar…` palette only lists Apple's built-in items:** Back/Forward, Path, Group, View, Action (⋯), Eject, Burn, Space, Flexible Space, New Folder, Delete, Connect, Get Info, Search, Quick Look, Share, Edit Tags, Preview, AirDrop, iCloud. **Nothing else.** No Shortcuts.app shortcuts, no Quick Actions, no Services, no Automator workflows.

This is a long-standing Finder limitation, not a Sequoia regression. It has never accepted user-built actions into the Customize Toolbar palette.

## What you CAN do for one-click Finder triggering

### 1. ⌘-drag a `.app` bundle onto the toolbar — TRUE one click

Hold ⌘ and drag any `.app` from Finder onto the toolbar of a Finder window. It pins as a toolbar button. Click it = launch the app. Drop files on it = `open -a` semantics (the files become the app's arguments / first-Apple-event argument).

This is the only Apple-blessed path to a single-click custom toolbar button.

**Pattern for "do X to current Finder selection":**

1. Build a tiny `.app` (Automator → Application, OR Swift `NSApplicationMain` reading `NSAppleEventManager` open-files events, OR a `.app` shell wrapper).
2. The app reads either `NSAppleEventManager` open-files arguments OR (if launched bare from toolbar with no drop) queries `Finder` via System Events / scripting bridge for `selection of front Finder window`.
3. ⌘-drag the `.app` onto Finder's toolbar.
4. Click it = "do X to current Finder selection".

This works because Finder's toolbar IS a launcher surface for `.app` bundles. It is NOT a launcher surface for Shortcuts or Services.

### 2. Action (⋯) menu — two clicks

The built-in **Action** toolbar button exposes Quick Actions registered via Shortcuts.app or Services. If you enabled a Shortcut as "Use as Quick Action → Finder" in Shortcuts.app, it appears under ⋯ → Quick Actions. Two clicks (⋯, then the action name) instead of one.

### 3. Right-click → Quick Actions submenu

Same Quick-Action registration shows up here too. Three clicks (right-click, Quick Actions submenu, action name) — what the user already does today.

### 4. Keyboard shortcut

System Settings → Keyboard → Keyboard Shortcuts → Services / App Shortcuts → assign a key combination (e.g. ⌃⌥⌘P) to the Shortcut or Service. Zero clicks, but requires a free key combination.

### 5. AppleToolbox menu-bar item

Add a "Tag: Process selection" entry to `topbar/AppleToolbox.swift` that reads `Finder selection` via NSAppleScript and calls `bin/tag add process`. One click (in the menu bar, not the Finder toolbar).

### 6. Hardware controller button

Loupedeck Live / Stream Deck / Contour ShuttlePro button bound to `osascript` that reads Finder selection and tags it. One click, hardware-physical.

## What we tried that DID NOT work (2026-05-26)

- Built a signed `.shortcut` file, imported it into Shortcuts.app. Confirmed visible in `shortcuts list`.
- Opened `View → Customize Toolbar…` in Finder. **The Shortcut was not in the palette.** Only the 19 built-in items were shown.
- The instruction "drag the Shortcut into the toolbar via Customize Toolbar" — that I gave the user — was wrong. Finder simply does not surface shortcuts there.

## Default recommendation for "tag selection from Finder toolbar with one click"

**Build a `.app` bundle and ⌘-drag it onto the toolbar.** Everything else costs an extra click or a keystroke. The `.app` approach is the only true one-click toolbar button macOS Finder supports.

## Tag-app generator + fresh-Mac bootstrap (built 2026-05-26)

The Apple-way answer to "give me Finder toolbar buttons for all my tags": one slash, full sweep.

### What it does

1. Walks every file under `~` that Spotlight has tagged: `mdfind 'kMDItemUserTags == "*"'`.
2. Reads each file's `com.apple.metadata:_kMDItemUserTags` xattr. Each entry is `"name\nN"` where `N` ∈ 0-7 maps to none|gray|green|purple|blue|yellow|red|orange.
3. Builds `{tag_name: Counter(color → file-count)}`, picks the most-common color per tag.
4. Generates `/Applications/AppleToolbox/Apple-Tag-Apps/Tag <Name>.app` for each unique tag, with a colored SF-Symbol `tag.fill` icon rendered via `bin/render-tag-icon.swift` (AppKit, no deps) → `.iconset` → `iconutil -c icns` → embedded as both `applet.icns` and `droplet.icns`.
5. Each .app implements `on open theItems` (drops) AND `on run` (bare launch reads Finder selection via `tell application "Finder" to get selection`), calling `bin/tag add <name>:<color>` per file.

### One-shot bootstrap

```
/tag-app                  # discover all + build all
/tag-app --dry-run        # preview the plan first
/tag-app <name> [color]   # one specific tag
```

First Esa run (2026-05-26): 6,688 tagged files scanned → 46 unique tags discovered → 46 colored .apps built in seconds. Colors auto-inferred from real usage: `ocr-failed`=orange, `ocr-complete`=green, `tesla`=red, `process`=purple, `schauberger`=blue, etc.

### Then pin

Open `/Applications/AppleToolbox/Apple-Tag-Apps/`, ⌘-drag whichever .apps deserve toolbar slots into Finder's toolbar. Each pin = one click on selection → tag applied. Drop also works.

### Fresh-install loop

When the apple skill lands on a new Mac, `/tag-app` is the single command that converts the user's existing Finder tag system into a usable toolbar palette. Re-run any time new tags appear to refresh the catalog.

Underlying tools: `bin/build-tag-app <name> [color]` (single), `bin/build-tag-apps [--discover|--dry-run|--colors|<names>]` (bulk), `bin/render-tag-icon.swift <color> <out.icns>` (Apple-native colored-icon renderer).

### One-time toolbar pinning (manual, by design)

After generating, open `/Applications/AppleToolbox/Apple-Tag-Apps/` and ⌘-drag each `Tag X.app` onto your Finder window's toolbar. The icon pins. Click = tag selection. Drop = tag dropped files.

Finder writes the pinned-app bookmark into `com.apple.finder.plist` under `NSToolbar Configuration Browser` as opaque `NSToolbarItem-<UUID>` entries with bookmark-data blobs. Programmatic injection of those blobs is reverse-engineering territory — bookmark data must be generated via `NSURL.bookmarkDataWithOptions:` (Apple-native via ASObjC, doable), then inserted into the NSToolbar config dict, then `killall Finder` to pick it up.

**Status of programmatic toolbar injection (2026-05-26):** not yet built. Requires reading the plist diff after a single manual ⌘-drag to confirm the exact bookmark-data structure Finder writes, then porting that to a generator. Until then, the one-time manual ⌘-drag is the documented workflow. Open issue in the wiki.

## Related

- [global-keyboard-shortcuts.md](global-keyboard-shortcuts.md) — Carbon RegisterEventHotKey in AppleToolbox, the fourth channel.
- [finder-sidebar-locked.md](finder-sidebar-locked.md) — companion gotcha: `LSSharedFileList` is dead on Sequoia, same drag-manually fallback applies.
- [finder-tag-pipeline.md](finder-tag-pipeline.md) — `bin/tag`, tag-watcher, Smart Folders.
- [dock-management.md](dock-management.md) — Dock is the OTHER `.app` launcher surface; same `.app`-bundle pattern works there.
