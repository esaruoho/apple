# Feature card: Sensor Snapshot — automated capture of every camera, the iPhone screen, and every audio input

> WHAT THIS CARD SPAWNS
> - **Codespace:** `sensor-snapshot/` (Swift sources + `build.sh` → `Snapshot.app`, the faceless bundle that carries the Continuity-camera key + Camera/Mic TCC identity) and `bin/{iphone-photo,iphone-import,audio-snippets,iphone-screen,snapshot}` wrappers.
> - **Thinkspace:** `sensor-snapshot/snapshot.session.md` (the spawning conversation: every fork, every honest "that's impossible", every KVO landmine).
> - **Areaspace:** OWNS capturing local sensors (Mac + USB-tethered iPhone) to files. Does NOT touch Photos library writes, does NOT UI-hijack, does NOT run anything on the iPhone itself.

## RESULT
- **Status:** built + shipped; two `@blocked-physical` claims pending phone USB-trust/unlock.
- **Delivery:** feature commit `d6031ca` on `main` (direct-push, no PR); indexes auto-regen `211be7c`.
- **Files:** `sensor-snapshot/{iphone-photo,iphone-import,audio-snippets,iphone-screen}.swift`, `sensor-snapshot/{Info.plist,build.sh,.gitignore}`, `bin/{iphone-photo,iphone-import,audio-snippets,iphone-screen,snapshot}`, `wiki/concepts/sensor-snapshot.md`.
- **Bundle:** `Snapshot.app` (id `com.esaruoho.apple.snapshot`), 4 faceless binaries (gitignored build artifact).

## Grades legend
`@verified` ran live, observed the artifact · `@built` compiles + runs, not fully exercised · `@blocked-physical` correct, gated on phone state · `@impossible` architecturally unavailable

---

Feature: Every camera → a file
  @verified
  Scenario: Capture all available video devices
    Given a Mac with FaceTime + virtual cameras (and an iPhone Continuity Camera when eligible)
    When I run `iphone-photo --all <dir>`
    Then one JPEG per device is written into <dir>
    # innards: sensor-snapshot/iphone-photo.swift capture()+--all loop; verified 5/5 cameras
    # (FaceTime + 2 virtual + iPhone rear 1920x1440 + iPhone Desk View) with phone present

  @verified
  Scenario: Rear iPhone camera via Continuity
    Given the iPhone is Continuity-eligible (unlocked once, BT+Wi-Fi, same Apple ID)
    When I run `iphone-photo <out.jpg>`
    Then a ~1920×1080 JPEG from the iPhone rear camera is written
    # innards: pickDevice() prefers .continuityCamera; verified live (1920x1080)

  @impossible
  Scenario: Front iPhone camera from the Mac
    Given only the Mac drives the capture
    Then the front camera cannot be reached
    # Continuity Camera exposes ONLY the rear system; no front position/device exists.
    # Front capture needs on-device software + a tap, which the no-UI-hijack rule bans.

Feature: Full-resolution iPhone photo (the real Camera.app file)
  @blocked-physical
  Scenario: Import the newest / next photo over USB
    Given the iPhone is tethered, trusted, AND unlocked
    When I run `iphone-import --latest <dir>` (or `--watch`)
    Then the 12MP/48MP HEIC/JPEG is copied off the phone via ImageCaptureCore
    # innards: sensor-snapshot/iphone-import.swift; device discovered + session opens live,
    # blocked only on "Please unlock" (DCIM gate) — code path correct, not yet green.

Feature: iPhone screen → a file
  @built
  Scenario: Grab the tethered iPhone screen
    Given CoreMediaIO screen-capture devices are enabled and the phone is unlocked + trusted
    When I run `iphone-screen <out.jpg>`
    Then a JPEG of the iPhone's screen is written
    And if no screen device is present it exits non-zero cleanly
    # innards: sensor-snapshot/iphone-screen.swift (kCMIOHardwarePropertyAllowScreenCaptureDevices
    # + VideoDataOutput). Enable call returns status=0; device did not enumerate while phone locked.
    # The graceful "no screen device" path IS verified; a real screen frame is NOT yet.

Feature: 5 snippets from every audio input
  @verified
  Scenario: Per-device snippets
    Given N audio input devices
    When I run `audio-snippets <dir> --count 5 --len 3 --gap 3.75`
    Then 5 clips per device land under <dir>/<device>/
    # innards: sensor-snapshot/audio-snippets.swift; verified 6 devices, file-poll finalization
    # (the AVCaptureFileOutput delegate never fires — same KVO landmine — so we poll the file).

  @verified
  Scenario: Per-channel split of multichannel inputs
    Given a multichannel device (e.g. the 7-channel Aggregate)
    When I add `--per-channel`
    Then each channel is written as its own mono Float32 .caf
    # innards: splitChannels() via AVAudioFile; verified CalDigit 2ch→2, Aggregate 7ch→7

Feature: One automated snapshot
  @verified
  Scenario: Fire everything into one timestamped folder
    When I run `snapshot [<dir>] [--quick] [--per-channel]`
    Then cameras/, screen/, audio/ and manifest.md are produced under snapshot-<timestamp>/
    And missing sensors (locked phone) are recorded in the manifest, not fatal
    # innards: bin/snapshot orchestrator; verified end-to-end (5 cameras incl. iPhone rear,
    # 12 clips across 6 inputs, screen gracefully skipped while phone untrusted-over-USB)

## Two known truths (the honest grades)
- The **AVCapture*Output KVO landmine** recurs across PhotoOutput AND FileOutput in a `swiftc` binary, even inside a bundle. Both camera and audio paths avoid it (VideoDataOutput frame-grab; file-polling instead of the recording delegate).
- Continuity Camera stills cap at **~2.8MP** — `AVCapturePhotoOutput` buys nothing over the frame-grab here.
