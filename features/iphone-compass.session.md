# Session — iphone-compass.feature

## How to get back
- Session ID: `070edd2e-d868-47ea-a2ba-a8104dd6a979`
- Resume: `claude --resume 070edd2e-d868-47ea-a2ba-a8104dd6a979`
- Date: 2026-10-16
- Repo: `/Users/esaruoho/work/apple`

## The request
Esa: "we have a method of extracting an image from an iPhone directly to file.
Can we use Apple SDK/API, when iPhone is plugged in, to use the iPhone as a
compass so we can figure out where East is — either boot up Compass on the
iPhone, or use its info to get heading data to the command line. figure it out."

## What was decided
1. **Direct sensor route rejected (evidence-backed).** Probed `CLLocationManager`
   / `CLHeading` → both PUBLIC classes, but a Swift probe showed
   `CLLocationManager.headingAvailable() == false` on this Mac. The Mac has no
   magnetometer and Apple exposes NO public USB/Continuity channel for iPhone
   heading (`CLHeading`/`CMHeadingData` are iOS-only). A custom iOS app pushing
   heading over a socket is the only true direct route — rejected as overkill.
2. **Screen → OCR route chosen**, reusing existing tools (DRY):
   `bin/iphone-screen` (CoreMediaIO frame, same mechanism as image extraction)
   → `bin/vision-ocr` (Apple Vision) → new `bin/compass.py` parser + East math.
3. Built `bin/compass` + `bin/compass.py`; parser self-test 11/11 PASS.

## Honest grade
- Parser + turn-to-East math: `@code-verified` (selftest green).
- Live capture leg: `@hw-untested` — NO iPhone was connected this session
  (`iphone-screen --list` → 0 devices). Not claimed as working on hardware.

## Update — remote launch SOLVED (2026-10-16, same session)
Esa: "command the iPhone to open up Compass now."
- iPhone was on the USB bus (`0x05ac:0x12a8 Apple Inc. iPhone`) and paired:
  `xcrun devicectl list devices` → esaiPhone16Pro, available (paired),
  id 3C55D532-8471-567F-9BBA-9FB0B9C954BE.
- `xcrun devicectl device process launch --device <id> com.apple.compass`
  → "Launched application with com.apple.compass bundle identifier." exit 0.
- CORRECTION: my earlier "no clean USB way to launch an iOS app remotely" was
  WRONG. devicectl (Xcode CoreDevice) launches apps by bundle id on a paired
  device, no custom app / URL scheme needed. Wired into `compass --open`.

## Update 2 — "locked" diagnosis was WRONG (2026-10-16, same session)
Esa: "the phone is not locked. the phone is open. it has not asked me for
permission or access." Correct. Re-investigated:
- Camera TCC for the probe binary = `authorized`.
- A 3s-wait CMIO DAL probe DOES surface the phone — but as
  `esaiPhone16Pro Camera [AVCaptureDeviceTypeExternal]` (Continuity Camera) and
  `esaiPhone16Pro Microphone`. There is NO screen-capture device.
- So the blocker is NOT lock and NOT TCC. The iOS screen-mirror DAL device
  (`iOSScreenCaptureAssistant`) is not surfacing; only Continuity Camera is,
  which films the room, not the phone's own screen — useless for reading the
  Compass readout.
- Next options for the READ leg (not yet done): (a) trigger a screen-mirror
  session so the screen DAL device appears (QuickTime "New Movie Recording"
  historically does this; iPhone Mirroring.app on Sequoia is another); (b)
  abandon screen-OCR and reconsider whether any non-screen path exists (none
  found — no sensor API). The LAUNCH capability is fully solved regardless.

## devicectl capability LOGGED
- Wrote wiki/concepts/iphone-app-launch-devicectl.md (the reusable skill:
  launch/suspend/resume/signal ANY of 186 enumerable apps by bundle id).

## Update 3 — READ leg abandoned by decision (2026-10-16)
Confirmed via direct CMIO enumeration that the USB-C iPhone 16 Pro exposes only
`esaiPhone16Pro Camera` + `esaiPhone16Pro Desk View Camera` — NO screen-capture
device. So iphone-screen/iphonemirror cannot see the phone's own screen; this is
a hardware/OS reality, not lock or TCC (Camera auth = authorized, Screen
Recording TCC = true). iPhone Mirroring.app is the only real-screen path but
needs the phone LOCKED and wouldn't stay open while the phone was in use.
Offered iPhone Mirroring vs QuickTime vs stop; Esa chose STOP. The compass READ
leg is parked as hardware-infeasible without a custom iOS app. The devicectl
LAUNCH capability (`compass --open` + the wiki page) is the kept deliverable.
