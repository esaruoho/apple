---
description: How to reliably detect a Lightning-connected iPhone on macOS, why system_profiler lies, and the A12 hardware gate that blocks Continuity Camera on iPhone X.
---

# iPhone over USB — detection, pairing, and the capture paths

## `system_profiler SPUSBDataType` is NOT a reliable presence check

Observed 2026-08-14: with an iPhone X actively connected and enumerated, `system_profiler
SPUSBDataType` returned an **entirely empty tree** — three `USB 3.1 Bus` host-controller stanzas,
zero `Product ID:` lines, and it had also dropped a USB hub that was genuinely present minutes
earlier. It is not that the device was missing; the whole dump collapsed.

**Never conclude "the device isn't connected" from `SPUSBDataType` alone.** It stalls / returns
partial or empty output under load. Add `-timeout N` and cross-check.

### The reliable probes, in order

```bash
# 1. IORegistry — ground truth for USB enumeration
ioreg -p IOUSB -w0 -l | grep -E '"USB Product Name"|"idVendor" = 1452|"USB Serial Number"'

# 2. MobileDevice / ImageCapture log — gives name, UDID, iOS build, PAIRING STATE
log show --last 5m --predicate 'senderImagePath CONTAINS "MobileDevice" OR eventMessage CONTAINS "iPhone"' --style compact

# 3. Pairing / lockdown errors specifically
log show --last 5m --predicate 'eventMessage CONTAINS "Could not pair" OR eventMessage CONTAINS "0xe800"' --style compact

# 4. Has this Mac ever paired with ANY iOS device?
ls -la /var/db/lockdown/        # empty  = never paired (or reset)
```

Apple's USB vendor ID is `0x05AC` = **1452 decimal**. `ioreg` prints it in decimal, `system_profiler`
in hex — grep for both. An iPhone in normal mode reports product ID `0x12A8`.

## Pairing state is the usual blocker, and it has its own error codes

An **untrusted** iPhone still enumerates over USB and still charges, but exposes only the PTP camera
interface (`/System/Library/Image Capture/Devices/PTPCamera.app`, `ICDeviceType = Camera`). Nothing
that needs lockdown works. Signatures:

| Signal | Meaning |
|---|---|
| `DevicePairedState = 0` | not trusted |
| `0xe8000016` — *Cannot retrieve value from the passcode-locked device* | phone is locked |
| `0xe800001a` | pair attempt refused (locked / Trust not tapped) |

**Fix:** cable in, unlock the phone, tap **Trust This Computer**, enter the passcode. A record then
appears in `/var/db/lockdown/`.

Enumeration also answers "is it charging?" — a phone that appears in `ioreg` over a Mac USB-C port is
drawing power from it. There is no way to read the phone's battery percentage from the Mac while
unpaired.

## Continuity Camera has a hardware gate: A12 / iPhone XR or newer

**Continuity Camera (iPhone-as-webcam, macOS Ventura+) does not work on iPhone X, wired or
wirelessly.** It requires an A12 Bionic or later — iPhone XR/XS and up. iPhone X is A11. This is a
hardware requirement, not a toggle; "wired Continuity" is not a workaround for it, because the wired
mode is the same feature with the same gate.

### What DOES work on an iPhone X — the pre-Continuity QuickTime device-capture path

Predates Continuity Camera entirely (QuickTime + iOS 8 era), works over Lightning on any iPhone,
requires only trust pairing:

**QuickTime Player ▸ File ▸ New Movie Recording** → click the ⌄ next to the record button → pick
**<iPhone name>** in the Camera list.

**Critical distinction: this gives you the iPhone's SCREEN, not its camera feed.** It is the iOS
screen-mirroring-over-Lightning feature, not a webcam feature. There is no chrome-free camera source
on this path.

To capture what the *lens* sees on a pre-A12 iPhone, select the iPhone in QuickTime and then open the
**Camera app on the phone** — the viewfinder fills the screen, so you get the camera view with the
Camera app's UI framing it. Crop in post (or in RecBurn) to trim the chrome. A genuinely clean camera
feed requires either Continuity Camera (A12+) or a third-party virtual-camera app that installs a
CoreMediaIO DAL plugin (Camo, EpocCam).

The iPhone appears in the `AVCaptureDevice` list only once trusted — an untrusted phone is absent from
it entirely, even while fully enumerated in `ioreg`. That absence is a pairing symptom, not a
missing-device symptom.

## `iOSScreenCaptureAssistant` is the component to grep for

When an iPhone won't appear in QuickTime's camera list, the decisive evidence is in this one process —
it is what publishes a Lightning iPhone as a capture source, and it spawns **on demand** (it is not
resident, so `pgrep` finding nothing means nothing):

```bash
log show --last 15m --predicate 'subsystem == "com.apple.mobiledevice"' --style compact \
  | grep -iE "iOSScreenCaptureAssistant|pair|lockdown"
```

Observed 2026-08-14 on macOS 15.6.1 with an iPhone X (iOS 16.7.11):

```
iOSScreenCaptureAssistant  RemotePairing.framework version: <private>
iOSScreenCaptureAssistant  Could not pair with the device 11: 0xe800001a
```

That is a **pairing** failure, not a capture failure — the feature and the OS are fine, the device is
not paired. Do not diagnose it as "iPhone too old" or "QuickTime doesn't do this".

### Diagnosing a Trust tap that didn't stick

| Evidence | Reading |
|---|---|
| Device ID incrementing (`8 → 9 → 10 → 11`) every ~45 s | link is dropping; a handshake can't complete across it. Check cable/port/lint. Compare `sessionID` in `ioreg` — unchanged = stable |
| `0xe8000016` passcode-locked at every attempt | phone auto-locked mid-handshake |
| `0xe8000084` kAMDDeviceDisconnectedError on port 62078 | lockdown port unreachable, usually follows a re-enumeration |
| `0xe800001a` Could not pair | the actual refusal |

Fixes, in order:

1. **Auto-Lock → Never** (Settings ▸ Display & Brightness). Pairing needs the phone unlocked at the
   moment the assistant fires, and it fires on demand — often after the screen has dozed.
2. **Settings ▸ Face ID & Passcode ▸ Accessories → ON.** With it off and the phone locked >1 h, iOS
   USB Restricted Mode blocks USB *data* while still accepting *charge* — enumerates, charges, won't
   pair.
3. **Reset Location & Privacy** (Settings ▸ General ▸ Transfer or Reset iPhone ▸ Reset) to clear
   wedged trust state, then replug with the phone awake and tap Trust.

Success tells: the assistant gets a session instead of `0xe800001a`, and QuickTime's recording window
resizes off its default 1280×720 to the device's aspect (2.16:1 for iPhone X).

## The assistant EXITS while you watch a Continuity Camera

`iOSScreenCaptureAssistant` is not resident. It is spawned on demand, and it **exits when no
screen-capture device is in use** — which is exactly the situation while you are watching a
Continuity Camera instead of a screen mirror.

Once it is gone, **plain enumeration will not bring it back.** Every iPhone silently reports as
absent even though `ioreg` shows it plainly on the bus. Setting
`kCMIOHardwarePropertyAllowScreenCaptureDevices` is what respawns it, so any long-running app must
**re-assert that property periodically**, not once at launch:

```swift
// iPhoneMirror re-asserts on every 3s device rescan
allowScreenCaptureDevices()
```

Measured 2026-08-14: with a Continuity Camera window open, both an iPhone X and an iPhone 16 Pro
vanished from enumeration (22 `IOUSBHostDevice` nodes present the whole time) and
`pgrep iOSScreenCaptureAssistant` returned nothing. Quitting the app respawned it.

## One phone gives you EITHER its screen mirror OR its Continuity Camera

These devices are **single-client**. Consequences worth knowing before debugging:

| Situation | Result |
|---|---|
| QuickTime has a Movie Recording window on a phone | nothing else can even *see* that phone |
| Your app mirrors phone A's screen | phone A's Continuity Camera stops publishing |
| Two apps both want the same phone | second one fails at `AVCaptureDeviceInput` |

So handle a failed open per-device and carry on with the others, rather than failing the whole app.

An A12-or-later phone publishes **both** kinds, e.g. `esaiPhone16Pro` (screen) and
`esaiPhone16Pro Camera` (Continuity). Never auto-open both — that gives one phone two windows.

### Prefer Continuity when the hardware has it

A Continuity Camera is a clean, upright, landscape camera feed: no Camera.app chrome, nothing to
crop, nothing to rotate. **Do not run orientation/crop heuristics on it** — OCR-ing whatever the
lens happens to see makes the orientation flip-flop on every re-detect. Pin it at 0°, uncropped.

Rule of thumb: pre-A12 (iPhone X and older) → screen mirror plus the crop machinery is the only
option. A12+ → Continuity, and skip all of it.

## Charging rate note

A USB hub is the wrong place to fast-charge. Observed VIA-Labs hub advertised **500 mA (2.5 W)** on
its USB2 side and **900 mA (4.5 W)** on USB3. A Mac USB-C port is substantially better; a 20 W USB-PD
wall brick is best (iPhone X supports ~18 W PD). Charge on the brick, move to the Mac only for the
capture session.

## Related

- [`asobjc.md`](asobjc.md) — default tooling tier
- [`../devices/README.md`](../devices/README.md) — device pages
