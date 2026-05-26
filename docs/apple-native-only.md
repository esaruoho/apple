---
layout: default
title: "Apple-Native Only — No Third-Party Dependencies"
---

# Apple-Native Only — No Third-Party Dependencies


[← Back to home](./)
**Rule for this skill:** every solution uses Apple-shipped technologies only. No Homebrew, no `pip install`, no `npm`, no third-party CLIs (`imagesnap`, `ffmpeg`, etc.). The apple skill is about using Apple to the max.

## Tool order (updated 2026-05-22 after Sal's ASObjC pointer)

When a problem looks like it needs an external CLI, pick in this order:

1. **AppleScript + AppleScriptObjective-C (ASObjC)** — the default. `use framework "Foundation"` at the top of a plain `.applescript` file unlocks every public Cocoa class — `NSFileManager`, `NSURL`, `NSMetadataQuery`, `NSWorkspace`, `NSPasteboard`, `NSImage`, `NSPropertyListSerialization`, `NSDistributedNotificationCenter`, every Foundation/AppKit/CoreImage class. Runs in `osascript`. Compiles into `.app` bundles via `osacompile`. Drops into Shortcuts via "Run AppleScript". Triggers from Loupedeck/Stream Deck natively. See [`asobjc.md`](asobjc.md).
2. **Python stdlib** — when no public Cocoa class exists for the domain. **Verify with `bin/cocoa-class-probe <ClassName>` before saying a Cocoa class name out loud.** PUBLIC = use ASObjC. ABSENT = use Python. Example: `NSSavedSearch` is ABSENT, so Smart Folders use `plistlib`.
3. **Swift compile** via `/usr/bin/swiftc -O -o binary script.swift` — only when AS+ASObjC truly cannot reach (KVO subclassing for AVFoundation, custom `NSWindow` subclasses, Carbon hotkeys via menu-bar apps, complex AppKit views).
4. **`do shell script`** with Apple-shipped binaries (`mdfind`, `defaults`, `osascript`, `screencapture`, `say`, `diskutil`, `networksetup`, `ioreg`, `system_profiler`, `pmset`, `xattr`, etc.) — for orchestration and for places where the Cocoa equivalent isn't worth it (e.g. `xattr -wx` is cleaner than poking private `setxattr` from Cocoa, since Foundation doesn't expose it publicly).
5. **Shortcuts** + Run AppleScript / Run Shell Script actions — for user-facing triggers and Siri/Spotlight reach.

**Hard rule:** Before naming any Cocoa class in a proposal, run `bin/cocoa-class-probe NSXxxx`. PUBLIC required. ABSENT means the name is wrong (pattern-matched from a plausible shape). The probe is the antidote to hallucinating class names.

Concrete examples (recorded 2026-05-08):
- `Take My Picture` originally used `imagesnap` (Homebrew) — replaced with `bin/sal-take-photo.swift` running via `/usr/bin/swiftc -O` then the compiled binary. Native AVFoundation (`AVCaptureVideoDataOutput` + `CIImage` + `CGImageDestination`).
- `QR This` / `QR My Clipboard` use `bin/sal-qr.swift` — Core Image `CIQRCodeGenerator`. Zero install.

**Compile-once vs script-mode caveat:** `/usr/bin/swift script.swift` runs Swift script-mode and works for simple scripts, but **fails on AVFoundation classes that need KVO subclassing** (`AVCapturePhotoOutput` produces `class 'NSKVONotifying_AVCapturePhotoOutput' not linked into application`). For those, compile via `swiftc -O -o binary script.swift` ahead of time, OR use sample-buffer-based APIs (`AVCaptureVideoDataOutput`) which don't have the KVO problem. The Take My Picture Shortcut self-bootstraps via `swiftc` on first run if the binary is missing.

If a task genuinely cannot be done Apple-native, document why and ask before introducing a dependency.
