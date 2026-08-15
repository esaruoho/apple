# DualCam

Front **and** rear iPhone cameras at once, fullscreen, so the phone's screen can be captured
over USB by [iPhoneMirror](../iphonemirror).

## Why this exists

macOS cannot receive an iPhone's front camera. Continuity Camera exposes the phone as **one**
`AVCaptureDevice` wired to the rear system, reporting `position=unspecified` — there is no
front/back selector to flip, and cabling does not change that. The capture has to happen on the
phone.

iOS can do what macOS cannot: `AVCaptureMultiCamSession` (A12 / iPhone XS and later) runs both
sensors simultaneously. This app composites them on the phone's own screen; the Mac picks that
screen up through the CoreMediaIO path, which has no device ceiling — so four phones is still
four phones.

## Build + install

```bash
./build.sh            # build, and install to a connected iPhone if one is plugged in
```

Needs Xcode and a signing identity; both are configured for team `X5RGX55QYU`.

## Using it

Tap the screen to cycle layouts:

`side by side` → `rear + front PiP` → `front + rear PiP` → `rear only` → `front only`

Portrait stacks the two, landscape splits them left/right.

Everything about it serves being **filmed** rather than used: no chrome, no status bar, black
background, and the idle timer is disabled — a rig that sleeps after 30 seconds is not a rig.
