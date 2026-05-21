---
name: Tier 5 dark apps — three back-door pattern
description: Every "nearly dark" Apple app (no sdef, no App Intents, no URL scheme) is reachable through one of three back-doors. Codified 2026-05-08 after building Stickies, Console, Audio MIDI Setup, Image Capture exporters.
type: project
originSessionId: c9cf684f-ae13-48ad-8a1c-14f9dd2464c7
---
## The pattern

When an Apple app is classified Tier 5 (skill.md "Nearly Dark"), don't give up. Each one has reached via exactly one of three predictable back-doors:

1. **A CLI tool that's strictly more powerful than the GUI**
   - Console.app → `log show` (predicate filtering, time windows, signposts)
   - Audio MIDI Setup → `system_profiler SPAudioDataType / SPMIDIDataType`
   - Disk Utility → `diskutil`
   - Screenshot → `screencapture`
   - Activity Monitor → `ps`, `top`, `vmstat`, `ioreg`, `system_profiler`
   - System Settings (partial) → `defaults`, `networksetup`, `pmset`, `mdutil`
   - Time Machine ops → `tmutil`
   - Console diagnostic reports → `~/Library/Logs/DiagnosticReports/`

2. **A framework call via `/usr/bin/swift` one-liner**
   - Image Capture (cameras) → AVFoundation `AVCaptureDevice.DiscoverySession`
   - Photo Booth → AVFoundation (same path)
   - Audio MIDI device events → Core Audio + Core MIDI notification observers
   - USB hot-plug → IOKit DAEvents
   - Image Capture (iOS download) → ImageCaptureCore via Objective-C bridging
   - VoiceOver Utility → `defaults` for `com.apple.VoiceOver4` plist + AppleScript via System Events

3. **The plist or filesystem store the app actually persists to**
   - Stickies → `~/Library/Containers/com.apple.Stickies/Data/Library/Stickies/<UUID>.rtfd/TXT.rtf` + `textutil`
   - Mission Control / Spaces → `~/Library/Preferences/com.apple.spaces.plist`
   - Clock world cities → `~/Library/Containers/com.apple.clock/Data/Library/Preferences/com.apple.mobiletimer.plist`
   - Photo Booth → `~/Pictures/Photo Booth Library/Pictures/*.{jpg,heic,mov}` + `Recents.plist`
   - Image Capture prefs → `~/Library/Preferences/com.apple.imagecapture.plist`
   - Saved MIDI configs → `~/Library/Audio/MIDI Configurations/*.mcfg`

## How to apply

When asked to crack a new Tier 5 app:

1. First run `bin/app-plist-probe.py --app <name>` — that tells you immediately whether the app persists structured user data and where.
2. Check `which <obvious-cli>` — `system_profiler` data type names often follow `SP<Capability>DataType`.
3. Try a Swift snippet against the most obvious framework — AVFoundation for media, Core Audio/MIDI for audio, IOKit for hardware events.
4. If all three fail, the app actually IS Tier 6 (Launchpad, Time Machine browse-content, parts of Mission Control's spaces-switching).

## Build template

The exporter package shape is identical across Stickies, Console, Audio MIDI, Image Capture:

```
<name>-exporter/
├── README.md
├── .env.example          VAULT_PATH=~/work/apple/exported/<name>
├── .gitignore            (.env)
└── scripts/
    ├── <name>-exporter        bash wrapper
    └── <name>_exporter.py     argparse with subcommands status/list-or-foo/export
```

Subcommands always include `status`, listing commands per data shape, and `export` that writes a markdown vault under `~/work/apple/exported/<name>/`. Write actions (snap, create, append, delete) gate behind explicit flags and warn about app-running races.

## Why this exists

Building Stickies, Console, Audio MIDI Setup, Image Capture in one afternoon (2026-05-08) made it clear the same three back-doors keep showing up. Future Tier 5 unlocks should start by asking which back-door fits, not by hand-probing for hours. This memo + `bin/app-plist-probe.py` together cut the discovery cost to under 5 minutes per app.
