# Mission Control / Spaces — Extraction Research

> 2026-05-08. Live probe on Esa's Mac (macOS 15.6.1).

## TL;DR

Mission Control was previously classified Tier 6 (Completely Dark). **Reclassified to Tier 5** today.

The back-door: `~/Library/Preferences/com.apple.spaces.plist` (1,491 bytes, single key `SpacesDisplayConfiguration` with the full Monitor → Spaces tree).

## What `com.apple.spaces.plist` contains

```
SpacesDisplayConfiguration/
└── Management Data/
    ├── Age (timestamp)
    ├── Management Mode (1)
    └── Monitors[] — one entry per physical/virtual display
        ├── Display Identifier ("Main", or specific UUID)
        ├── Current Space (with id64, ManagedSpaceID, type, uuid, wsid)
        ├── Collapsed Space (when monitor is in Stage Manager strip)
        └── Spaces[] — every Space ID + UUID on this monitor
```

Each Space entry has:
- `id64` — 64-bit Space identifier
- `ManagedSpaceID` — equivalent
- `type` — 0 = user space, 4 = full-screen app
- `uuid` — empty string in default mode, populated for some configurations
- `wsid` — window-server ID (matches what `WindowServer` sees)

## What's NOT here

- Per-app Space assignments ("which apps live in which Space") — those live in the WindowServer's runtime memory and the Dock's `wvous-*` plist keys for hot-corner mappings.
- Mission Control gestures / keyboard-shortcut bindings — those are in `com.apple.symbolichotkeys.plist` (system-wide).
- Stage Manager state — `com.apple.WindowManager.plist`.

## Related plists worth knowing

```
~/Library/Preferences/com.apple.dock.plist           Dock + persistent-apps + recents
~/Library/Preferences/com.apple.spaces.plist         Spaces / Mission Control state
~/Library/Preferences/com.apple.WindowManager.plist  Stage Manager
~/Library/Preferences/com.apple.symbolichotkeys.plist  Mission Control / Spaces shortcuts
```

## What you can do with this

Read-only:
- List every Space and its current placement per monitor
- Detect which monitor is in Stage Manager strip mode (Collapsed Space)
- Cross-reference Space IDs against `WindowServer` log entries (with `console-exporter show --process WindowServer`)

Phase 2 (write actions, RISKY):
- Don't write to `com.apple.spaces.plist` while the user session is running. WindowServer overwrites it. Use it only as a snapshot source.
- For programmatic Space-switching, the only reliable Apple-native paths are:
  - `osascript` UI-scripting → Mission Control activation (`Ctrl+Up`) → click Space thumbnail
  - Keyboard shortcuts via `defaults write com.apple.symbolichotkeys` to assign Space N to a key combo
  - `yabai`-style WindowServer private API hooks (NOT Apple-native; requires SIP partial-disable; out of scope)

## Why the reclassification matters

The Tier 6 list now contains only:

- **Launchpad** — no plist, no CLI, no framework hook (LaunchServices for app metadata exists but doesn't expose the Launchpad UI grid)
- **Time Machine** for *browsing* backup *content* — `tmutil` covers operations (start/stop/list backups) but content browsing requires the Finder UI

So the Tier 5/6 split is now:

- **Tier 5**: every dark app where SOMETHING is mineable on disk or via a CLI
- **Tier 6**: only the apps where literally no on-disk persistence exists for the data the GUI shows

## Live numbers on this Mac

```
Monitors tracked:      2  (Main + secondary)
Spaces visible:        ≥3 (one entry per monitor + Collapsed Space)
plist size:            1,491 bytes
Last management age:   37,387 seconds (since the last Space reorganisation)
```

## No `mission-control-exporter` package built yet

Reason: Esa already has Loupedeck-driven window-management scripts (`MosaicWindows.scpt`, `MosaicKnob.scpt`) that operate on windows directly. A separate Mission Control exporter would only be useful if there's a need to *catalog* Spaces over time (e.g. "track how my Space layout changes across the workday"). If Esa wants that, the build is trivial: same shape as the others, single `status` + `export` (writes one md per monitor showing each Space).
