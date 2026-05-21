# Apple-Native Only — No Third-Party Dependencies

**Rule for this skill:** every solution uses Apple-shipped technologies only. No Homebrew, no `pip install`, no `npm`, no third-party CLIs (`imagesnap`, `ffmpeg`, etc.). The apple skill is about using Apple to the max.

When a problem looks like it needs an external CLI, write the equivalent in:
- **AppleScript** (with AppleScriptObjC bridge for framework access)
- **Swift one-liner** via `/usr/bin/swift <file.swift>` (interpreter ships with macOS — zero install)
- **`do shell script`** with macOS-native binaries (`mdfind`, `defaults`, `osascript`, `screencapture`, `say`, `diskutil`, `networksetup`, `ioreg`, `system_profiler`, `pmset`, etc.)
- **Shortcuts** + Run AppleScript / Run Shell Script actions

Concrete examples (recorded 2026-05-08):
- `Take My Picture` originally used `imagesnap` (Homebrew) — replaced with `bin/sal-take-photo.swift` running via `/usr/bin/swiftc -O` then the compiled binary. Native AVFoundation (`AVCaptureVideoDataOutput` + `CIImage` + `CGImageDestination`).
- `QR This` / `QR My Clipboard` use `bin/sal-qr.swift` — Core Image `CIQRCodeGenerator`. Zero install.

**Compile-once vs script-mode caveat:** `/usr/bin/swift script.swift` runs Swift script-mode and works for simple scripts, but **fails on AVFoundation classes that need KVO subclassing** (`AVCapturePhotoOutput` produces `class 'NSKVONotifying_AVCapturePhotoOutput' not linked into application`). For those, compile via `swiftc -O -o binary script.swift` ahead of time, OR use sample-buffer-based APIs (`AVCaptureVideoDataOutput`) which don't have the KVO problem. The Take My Picture Shortcut self-bootstraps via `swiftc` on first run if the binary is missing.

If a task genuinely cannot be done Apple-native, document why and ask before introducing a dependency.

