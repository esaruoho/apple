---
description: iPhoneMirror.app — live, auto-oriented, auto-cropped mirrors of USB iPhone/iPad screens, one window per device, tiled for one-shot screen recording.
---

# iPhoneMirror

`iphonemirror` / `/Applications/iPhoneMirror.app` — shows the screens (or Continuity Camera feeds)
of USB-connected iPhones in Mac windows, already rotated and cropped, so a **single** RecBurn pass
captures them correctly with no post-editing.

- Source: [`../../iphonemirror/iPhoneMirror.swift`](../../iphonemirror/iPhoneMirror.swift)
- Build + install: `iphonemirror/build.sh` (dittos to `/Applications`, regenerates the icon)
- Card: [`../../features/iphonemirror-rotated-live-mirror.feature`](../../features/iphonemirror-rotated-live-mirror.feature)
- Built 2026-08-14. Apple-native: AppKit + AVFoundation + CoreMediaIO + Vision, `xcrun swiftc`.
- **Standalone public repo: [esaruoho/iPhoneMirror](https://github.com/esaruoho/iPhoneMirror)** —
  flat layout, MIT, vendors `shared/SupportHelp.swift`. Store page:
  [lackluster.gumroad.com/l/iphonemirror](https://lackluster.gumroad.com/l/iphonemirror) (€13.54+).
  Keep both copies in sync; **the standalone is canonical on divergence**, as with `apple-rec` and
  `apple-energy`.

## Why it exists

QuickTime Player can mirror a Lightning iPhone, but **`Edit ▸ Rotate Left / Rotate Right / Flip`
are disabled during a live capture session** and its scripting dictionary has no rotate
terminology. So a phone held landscape whose iOS UI is locked to portrait cannot be un-rotated
live — only recorded and rotated afterwards, which kills a one-shot take. iPhoneMirror rotates the
`AVCaptureVideoPreviewLayer` instead.

## Usage

```bash
iphonemirror                       # menu-driven: nothing opens until you tick a device
iphonemirror --continuity          # also list Continuity Cameras (A12+)
iphonemirror --all                 # open every iOS screen mirror immediately
iphonemirror --device "16Pro Camera"
iphonemirror --list                # devices tagged by kind
```

`Devices` menu ticks each phone on/off; the list refreshes every 3s, so plugging one in makes it
appear. Rows persist as `(not connected)` rather than vanishing.

| Key | Action |
|---|---|
| ⌘1 / ⌘2 | Stack side by side / top and bottom (also leaves full screen) |
| ⌘3 | Full screen, **cycling** between phones forever |
| ⌘B | Title bar on/off on the front window |
| ⇧⌘L / ⇧⌘R / ⇧⌘H | Rotate left / right / flip |
| ⌘D | Resume automatic detection (after any manual tweak) |
| ⌘0 | Show the phone's whole screen, uncropped |
| ⌘[ / ⌘] | Nudge the crop |
| Space | Hide every other app |

Each device remembers its own rotation and crop by `uniqueID`; the saved value **seeds** a window
but never suppresses detection.

## How the automatic part works

Vision OCR reads the feed **continuously** (throttled to 1.2s, and only when a 16×16 grayscale
signature says the picture actually changed):

- **Orientation** is scored on **scene** text — the thing being filmed — *not* on upright chrome.
  Upright chrome indicates the iOS *UI* orientation, which is the wrong target: with Rotation Lock
  on, iOS draws its UI upright and turns the scene 90°.
- **Crop** is pure **geometry**: the viewfinder spans the full short edge, PHOTO mode is 4:3, and
  the mode wheel is located by name. Never by luminance — see the dead ends below.

## Hard-won facts

Full detail in [`../concepts/iphone-usb-capture-probe.md`](../concepts/iphone-usb-capture-probe.md)
and [`../concepts/appkit-window-gotchas.md`](../concepts/appkit-window-gotchas.md):

- `kCMIOHardwarePropertyAllowScreenCaptureDevices` must be set or an iOS device is **invisible** to
  `AVCaptureDevice` — and **re-asserted periodically**, because `iOSScreenCaptureAssistant` exits
  while a Continuity Camera is in use.
- Devices are **single-client**: one phone gives you mirror *or* Continuity, never both.
- Four luminance-based crop approaches all failed, because the *subject* can be black (a DOS CRT).
- `isReleasedWhenClosed` and borderless `canBecomeKey` each cost a bug.

## Related

- [`../concepts/iphone-usb-capture-probe.md`](../concepts/iphone-usb-capture-probe.md)
- [`../concepts/appkit-window-gotchas.md`](../concepts/appkit-window-gotchas.md)
- [`../concepts/macos-app-icon-sizing.md`](../concepts/macos-app-icon-sizing.md)
