---
description: How a cabled iPhone appears to macOS as capture devices — the three device types, and the role exclusivity that makes two of them mutually destructive
---

# iPhone capture over USB

What a single cabled iPhone offers a Mac, what can run at the same time, and what cannot.
Measured on an iPhone 16 Pro + macOS 15.6.1 on 2026-08-17, with `bin/iphonemirror`.

## Not Apple's "iPhone Mirroring" app

macOS ships an app called iPhone Mirroring that is limited to **one device at a time**. None
of this uses it. `iphonemirror` uses the QuickTime-era **CoreMediaIO** path: set
`kCMIOHardwarePropertyAllowScreenCaptureDevices` and each iPhone appears as its own
`AVCaptureDevice`. That path has no documented device cap — multi-iPhone test farms are built
on it — so the one-device limit people quote does not apply here.

## One phone, three devices

A single iPhone 16 Pro enumerates as **three** capture devices:

| device name | what it is | measured |
|---|---|---|
| `<phone> Camera` | Continuity Camera, rear system | 1920x1080 @ 24fps |
| `<phone> Desk View Camera` | second stream, corrected crop of the ultra-wide | 1920x1440 @ 24fps |
| `<phone>` | the phone's SCREEN (CoreMediaIO) | 1206x2622 @ 54-60fps |

The screen device's name is a **prefix** of its cameras' names. That is how `--rig` recognises
which devices belong to the same phone without guessing from device types.

**Desk View must be asked for.** It only enumerates if `.deskViewCamera` is in the
`AVCaptureDevice.DiscoverySession` device types. iPhoneMirror originally requested only
`.continuityCamera`, so one phone could ever only produce one picture — a silent limitation
that looked like an Apple restriction and was ours.

## THE constraint: a phone serves ONE role at a time

**Opening the screen device takes the phone out of Continuity mode.** Its Camera and Desk View
windows go blurred and halt on their last frame.

This is nasty to diagnose, because **frames keep arriving**: a frozen Continuity Camera still
delivers its last picture, so a frame counter reads a healthy 24fps while nothing moves. The
count is not evidence; distinct frame *content* is. Esa spotted it by watching the windows
while the numbers said everything was fine.

Consequence for a rig:

- **Camera role** — 2 live streams per phone (Continuity + Desk View), both rear-derived, no app needed.
- **Screen role** — 1 stream per phone, but it can show anything, including both cameras (see [[dualcam]]).
- **Never both on one phone.** Mixing across *different* phones is fine.

`iphonemirror --rig` refuses to open a phone's screen while that phone is serving cameras, and
says why. `--prefer-screen` inverts the choice.

## macOS does not cap concurrent sessions

Measured with four devices at once, each in its own `AVCaptureSession`, all delivering
simultaneously at independent rates:

```
OBS Virtual Camera       69.0 fps
Insta360 Virtual Camera  34.8 fps
FaceTime HD Camera       28.4 fps
esaiPhone16Pro Camera    17.6 fps      → 4 of 4 delivering
```

So "can I run four phones" is not a macOS or AVFoundation question. The real ceiling is USB
bandwidth and hub topology, which is hardware-specific and only findable by plugging things in.

## The front camera is not available to macOS

Continuity Camera exposes the phone as **one** device wired to the rear system, reporting
`position=unspecified` — there is no front/back selector to flip, and cabling does not change
it. The only route to the front camera is an app on the phone using `AVCaptureMultiCamSession`
(A12 / iPhone XS or later), composited onto the phone's screen and captured via the screen
role. That is what [[dualcam]] exists for.

## Gotchas

- **A stat that says "dead" about a working device is worse than no stat.** `--rig` fps read
  0.0 for camera devices because the frame counter lived on an output that is only attached
  when orientation detection is on, and camera feeds skip detection. The picture was fine.
- **Screen devices leave `activeFormat` empty** (0x0). Their dimensions only exist once frames
  arrive, so read them from the sample buffers.
- **Developer Mode** must be enabled on the phone before any development app installs, and it
  needs a reboot. Installing immediately after that reboot fails with *"The device disconnected
  immediately after connecting"* — presence for one instant is not readiness. Require several
  consecutive sightings before attempting.
- **`devicectl list devices` last column is the MODEL**, not the identifier
  (`iPhone 16 Pro (iPhone17,1)`). Parse `--json-output`, not columns.

Related: [[ios-free-provisioning-limits]], [[dualcam]].
