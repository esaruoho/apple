# image-capture-exporter

Image Capture surface unlocked. The app is Tier 5 dark — no
AppleScript dictionary, no App Intents, no URL scheme — but two
back-doors give us everything:

1. **AVFoundation** via `/usr/bin/swift` for video capture devices
   (built-in webcam, Continuity Camera, virtual cameras like OBS,
   external USB cameras, Insta360 / DSLR plug-ins).
2. **`system_profiler`** for connected iOS/iPadOS/Watch devices and
   USB scanners.

Apple-native only. No Homebrew, no `pip install`. The Swift snippets
ship in this package and run via the macOS-bundled compiler.

## Install

```bash
cd ~/work/apple/image-capture-exporter
cp .env.example .env
chmod +x scripts/image-capture-exporter
```

First call to `snap` prompts for **Camera access** (System Settings →
Privacy & Security → Camera). Approve once for Terminal.

## Commands

### `status` — quick overview

```bash
image-capture-exporter status
```

Lists every camera AVFoundation sees plus connected iOS/iPad/Watch
devices and any USB scanners.

### `cameras` — list video capture devices

```bash
image-capture-exporter cameras
image-capture-exporter cameras --json
```

Per camera: name, unique_id (stable), model_id, AVFoundation device
type, manufacturer, format count + sample formats (resolution + max
frame rate).

### `ios-devices` — connected mobile Apple gear

```bash
image-capture-exporter ios-devices
image-capture-exporter ios-devices --json
```

Walks the USB device tree (`SPUSBDataType`) and filters to entries
made by Apple matching iPhone / iPad / iPod / Apple Watch.

### `scanners` — flatbed / sheet-fed scanners

```bash
image-capture-exporter scanners
```

Filters the USB tree for "scan" / "scanner" name matches. (For
Bonjour-discovered network scanners, future Phase 2 would add
`mDNS` browsing via `dns-sd`.)

### `prefs` — Image Capture preferences

```bash
image-capture-exporter prefs
image-capture-exporter prefs --json
```

Reads `~/Library/Preferences/com.apple.imagecapture.plist`. Common
keys: download directory, "delete after import" preferences.

### `snap` — capture a photo (WRITE action)

```bash
image-capture-exporter snap                              # default camera, default location
image-capture-exporter snap --camera "FaceTime"          # match by name substring
image-capture-exporter snap --camera "Insta360"
image-capture-exporter snap --out ~/Desktop/test.jpg
```

Runs `take_photo.swift` — opens an `AVCaptureSession`, gives the
camera ~0.6 s to warm up, grabs one frame, encodes to JPEG, exits.
Default output: `~/work/apple/exported/image-capture/snaps/<timestamp>.jpg`.

### `export` — full markdown vault

```bash
image-capture-exporter export
```

Writes:

```
~/work/apple/exported/image-capture/
├── INDEX.md
├── cameras.md
├── ios-devices.md
├── scanners.md
├── preferences.md
└── snaps/
    └── 2026-05-08__102514.jpg     created by `snap` runs
```

## Phase 2 (not built yet)

- `download-from-ios <device>` — pull recent photos from a connected
  iPhone via the ImageCaptureCore framework (Objective-C bridging).
  This replicates Image Capture's main feature but as a CLI.
- `watch` — observe USB device-attach / detach events
  (`IOKit DAEvents` via Swift) and run a hook command per event:
  "every time iPhone plugs in, kick off photo import to ~/Pictures/Imported/".
- `record-video` — same Swift session as `snap` but with
  `AVCaptureMovieFileOutput` to record to .mov for N seconds. Useful
  for hardware-controller-triggered short clips.
- `mDNS scanners` — discover SANE / AirScan-capable network scanners
  via `dns-sd -B _scanner._tcp` and probe their config.

## Why this matters

Image Capture is the unsung Apple utility. It's the only
Apple-supplied way to bulk-pull photos off an iPhone without going
through Photos.app's import-everything-into-the-library model. By
exposing the device list as data, this exporter lets workflows
auto-react to phone plug-in, log device serials, capture quick
identity photos for journals, or kick off scanning sessions — none
of which the GUI affords.

## See also

- `bin/sal-take-photo.swift` — earlier single-purpose Swift snippet
  that this package generalised. The `snap` subcommand is a
  feature-parity replacement.
- `audio-midi-exporter/` — same `system_profiler` + Swift pattern,
  for the Core Audio / Core MIDI side.
- `bin/app-plist-probe.py` — scans every Apple app's plist; Image
  Capture's `com.apple.imagecapture.plist` shows up there too.
