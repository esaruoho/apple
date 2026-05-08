# Image Capture — Extraction Research

> 2026-05-08. Live probe on Esa's Mac (macOS 15.6.1).

## TL;DR

Image Capture is **Tier 5 dark** — no sdef, no App Intents, no URL scheme. Two complementary back-doors:

1. **AVFoundation** via `/usr/bin/swift` one-liner — `AVCaptureDevice.DiscoverySession` enumerates every video device the Mac can see (built-in webcam, Continuity Camera, Insta360 / OBS virtual cameras, external USB).
2. **`system_profiler SPUSBDataType -xml`** — recursively walked, filters to Apple iOS / iPadOS / Watch entries by manufacturer + name, and to scanner-named USB devices.

## AVFoundation device fields

Each `AVCaptureDevice` exposes (we serialize via Swift JSON):

- `localizedName` ("FaceTime HD Camera", "Insta360 Virtual Camera")
- `uniqueID` — stable across reboots, suitable as a primary key
- `modelID` — generic model string
- `deviceType` — `AVCaptureDeviceTypeBuiltInWideAngleCamera` / `Continuity` / `External` / `DeskView`
- `manufacturer`
- `isConnected` / `isInUseByAnotherApplication`
- `formats` — list of `AVCaptureDeviceFormat`s with resolution + supported frame-rate ranges

## SPUSBDataType walk

`system_profiler` returns a recursive USB hub tree. Flatten with a depth-walk, then filter by:

- `manufacturer == "Apple Inc."` AND `_name` contains iPhone/iPad/iPod/AppleWatch → iOS device
- `_name` contains "scan" → scanner candidate

Per-device fields surfaced: `_name`, `manufacturer`, `serial_num`, `vendor_id`, `product_id`, `device_speed`.

## `take_photo.swift` capture session

The package ships a Swift snippet that:

1. Selects the matching `AVCaptureDevice` (by name substring or first available)
2. Builds an `AVCaptureSession` with preset `.photo`
3. Adds an `AVCaptureVideoDataOutput` with a delegate
4. Starts the session, waits for one sample buffer (~600 ms warm-up)
5. Converts the pixel buffer → CIImage → CGImage → NSBitmapImageRep → JPEG (quality 0.92)
6. Writes the JPEG and exits

Pure Apple stack, no third-party dependencies. The first run prompts for Camera permission (TCC) — approve once for Terminal.

## Live numbers on this Mac

```
Cameras:          3   FaceTime HD, Insta360 Virtual, OBS Virtual
iOS devices:      0   (nothing plugged in)
USB scanners:     0
ImageCapture prefs:  1 key  (com.apple.imagecapture.plist)
```

## Implementation in `image-capture-exporter`

- `status` — three-line summary
- `cameras` — full AVFoundation dump, with sample resolution+fps formats per camera
- `ios-devices` — filtered USB tree
- `scanners` — same idea, name-substring filter
- `prefs` — plist read of `com.apple.imagecapture.plist`
- `snap` — WRITE: capture one JPG via `take_photo.swift`
- `export` — markdown vault: `cameras.md`, `ios-devices.md`, `scanners.md`, `preferences.md`, `INDEX.md`

## Phase 2 candidates

- `download-from-ios <device>` — pull recent photos from a connected iPhone via the **ImageCaptureCore** framework. Requires Objective-C bridging since IC is not Swift-friendly (NSDictionary-heavy ICDevice / ICCameraFile API).
- `watch` — observe USB device-attach / detach via IOKit `DAEvents`. Per-event hook command: "every time iPhone plugs in, kick off photo import to ~/Pictures/Imported/".
- `record-video` — same Swift session but with `AVCaptureMovieFileOutput` for short clip recording (Loupedeck-button-triggered).
- `mDNS scanners` — discover AirScan / SANE-capable network scanners via `dns-sd -B _scanner._tcp`.
- `continuity-camera-pair` — query / surface which iPhone is paired as Continuity Camera + battery state.

## Why this matters

Image Capture is the unsung Apple utility — the *only* sanctioned bulk-pull from iPhone that doesn't force everything into Photos.app. Exposing the device list as data lets workflows auto-react to phone plug-in, log device serials, capture quick identity photos for journals, or kick off scanning sessions — none of which the GUI affords.
