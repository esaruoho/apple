# CitrusPeel Library Index — Phase 1 Deliverable

**Source:** `sources/sal/macosxautomation.com/dictationcommands/CitrusPeel255.zip` (Sal Soghoian, November 2016)
**Decompiled:** 2026-05-07
**Engine of:** WWDC 2016 session 717 ("Beyond Dictation: Enhanced Voice Control for macOS Apps")

## Top-line numbers

| Metric | Value |
|--------|-------|
| Total `.scptd` AppleScriptObjC libraries | **18** |
| Decompiled lines of source AppleScript | **14,915** |
| Commands defined in `Custom Commands.plist` | **596** |
| Total spoken phrasings (each command can have multiple) | **1,966** |
| Application scopes | 9 (Maps, Photos, QuickTime, Finder, Calendar, Keynote, Numbers, Pages, Mail) + Global |

The `Custom Commands.plist` is the canonical spec — it maps every spoken phrase to a `tell script "DC-XXX" to handlerName()` invocation. Extracted to `commands.json` (machine-readable).

## Per-library breakdown

| Library | Lines | Role |
|---------|-------|------|
| **DC-Keynote** | 4,196 | Largest library. Slide creation, navigation, transitions, image manipulation, presenter notes, panoramic sequences, magic move, dissolve, save flow |
| **DC-Photos** | 1,981 | Photos.app: select, edit, search, geolocation, EXIF, descriptions, slideshow, export |
| **DC-Workspace** | 1,953 | The OS-level glue. Contains 4 helper apps embedded in Resources (App Announcer, AirDrop Helper, Overlay Text Helper, PictureTaker Helper). Spotlight bridge, file move/copy, AirDrop, screen capture |
| **DC-Assistive-Keynote** | 1,393 | The "help me with..." assistive flows for Keynote. Speaks slide info, locks/unlocks text items, walks user through tasks |
| **DC-Pages** | 814 | Pages document creation, edit, export |
| **DC-Calendar** | 719 | Day/week/month/year view jumps; demo event creation |
| **DC-Support** | 709 | Shared utilities: text transforms, undo (`Scratch That`), clipboard, system speech feedback |
| **DC-Image-Placeholder** | 586 | Placeholder image creation and management |
| **DC-Assistive-Photos** | 438 | Assistive flows for Photos (the "help me to add titles" walkthrough Sal demos at WWDC line 341) |
| **DC-Numbers** | 404 | Numbers tables, charts, table-to-Keynote chart export |
| **DC-Maps** | 300 | Maps geocoding, screen capture for export to Keynote |
| **DC-Mail** | 299 | Mail compose, reply, mailbox navigation |
| **DC-Keynote-Objects** | 298 | Object-level Keynote ops: scale, position, group, QR code generation |
| **DC-QuickTime Player** | 262 | Audio/screen/video recording start/stop |
| **Lorem Ipsum** | 199 | Dummy text generator (paragraphs of placeholder text) |
| **DC-iTunes** | 134 | iTunes navigation (Sal's pre-shipped 5 user commands) |
| **Alert Utilities** | 103 | Custom HUD via bundled `BigHonkingText` binary + speech feedback |
| **DC-Help** | 100 | "Show your help" command, Help Book launcher |
| **DC-Demo** | 27 | Smallest. Sentinel state machine for `Done` / assistive completion |

## Command distribution by scope

| Scope | Bundle ID | Commands |
|-------|-----------|----------|
| Global / system-wide | `com.apple.speech.SystemWideScope` | (the largest bucket — `Switch to`, `Search Spotlight for`, file-system ops, AirDrop, etc.) |
| Keynote | `com.apple.iWork.Keynote` | Slide-edit, transitions, panoramic, QR code, etc. |
| Photos | `com.apple.Photos` | Select, search, edit, geolocate |
| Numbers | `com.apple.iWork.Numbers` | Table select, export-as-chart |
| Pages | `com.apple.iWork.Pages` | Document create, edit, export |
| Calendar | `com.apple.iCal` | View navigation, demo events |
| Mail | `com.apple.mail` | Compose, mailbox navigation |
| Maps | `com.apple.Maps` | (geocoding/screen-capture launched via DC-Workspace and DC-Maps) |
| Finder | `com.apple.finder` | Folder navigation, item move/copy |
| QuickTime | `com.apple.QuickTimePlayerX` | New audio/video/screen recording |

## Key handler examples (Sal's WWDC 717 demo flow)

These are the handlers that back the 46-line `dictation-commands-main-example.txt`:

| WWDC line | Spoken | Library | Handler |
|-----------|--------|---------|---------|
| 341 | "Help me to add titles" | `DC-Assistive-Photos` | `describeAndChooseFromSelectedMediaItems()` |
| 350 | "Make a new presentation with these" | `DC-Photos` → `DC-Keynote` | (chained flow via `DC-Workspace`) |
| 357 | "Change master slide to title center" | `DC-Keynote` | (master-slide change handler in 4196-line file) |
| 380 | "Show this in Keynote" | `DC-Workspace` | (round-trip context handler) |
| 394 | "Show this in Maps" | `DC-Maps` | (geocoder + Maps URL) |
| 415 | "Apply a magic move" | `DC-Keynote` | (transition setter) |
| 421 | "Make a long panoramic sequence" | `DC-Keynote` | (multi-image auto-layout) |
| 422 | "Put descriptions on top of every image" | `DC-Workspace` (helper: Overlay Text Helper.app) | (description → text overlay) |
| 427 | "Search Spotlight for ..." | `DC-Workspace` | (Spotlight query + result picker) |
| 431 | "Export this table to Keynote as a chart" | `DC-Numbers` → `DC-Keynote` | (cross-app chained handler) |
| 461 | "Save this presentation to my thumb drive and eject it" | `DC-Keynote` + `DC-Workspace` | (save + cp + diskutil eject) |
| 462 | "Scratch that" | `DC-Support` | (undo handler) |
| 474 | "Turn this into a QR code" | `DC-Keynote-Objects` | (QR code generator) |
| 475 | "Scale down 10%" | `DC-Keynote-Objects` | (scale handler with percentage param) |

## Helper apps (embedded in DC-Workspace.scptd/Contents/Resources/)

| App | Purpose | TCC requirement |
|-----|---------|------|
| **App Announcer.app** | Speaks frontmost app name | Speech |
| **AirDrop Helper.app** | Triggers AirDrop send via UI scripting | Accessibility |
| **PictureTaker Helper.app** | Camera capture for "Take my picture" | Camera + Accessibility |
| **Overlay Text Helper.app** | Renders text overlays on Keynote slides | None (Keynote-internal) |
| **Photos Description Helper.app** (top-level) | EXIF/description reader for Photos | Photos library access |

## Files

- **Decompiled source:** `scripts/sal/dictation-commands/decompiled/*.applescript` (18 files, 14,915 lines)
- **Command catalog:** `scripts/sal/dictation-commands/commands.json` (596 commands, machine-readable)
- **Original installer:** `sources/sal/macosxautomation.com/dictationcommands/CitrusPeel255.zip` (untouched)
- **Extracted tree:** `scripts/sal/dictation-commands/citruspeel-extracted/` (gitignored — large, regenerable)

## Status

Phase 1 deliverable: **complete**. Engine is decompiled, indexed, and machine-readable. Ready for Phase 2 (port-readiness audit) and Phases 3–5 (generators).
