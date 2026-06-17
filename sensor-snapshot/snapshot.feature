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
  @built   # NOT yet verified for a freshly-taken photo — see the honesty note below
  Scenario: Import the next photo over USB — YOU shoot it
    Given the iPhone is tethered (and trusted+unlocked, retried for ~80s)
    When I run `iphone-import --watch <dir>` and take a photo in the Camera app
    Then the real HEIC/JPEG the phone just wrote is copied off via ImageCaptureCore
    # innards: sensor-snapshot/iphone-import.swift. Detection is by 2s POLLING (close→reopen
    # re-enumerates the catalog), because ImageCaptureCore's didAdd push event does NOT fire
    # for iPhone captures taken after the session opens. Compiles + runs; a freshly-taken photo
    # has NOT yet been observed landing through the poll. @built until that live observation.

  @verified
  Scenario: Survive starting before the phone is unlocked (retry, don't bail)
    Given the iPhone is locked when the command starts
    When the ImageCaptureCore session-open returns -9943 (ICReturnDeviceIsPasscodeLocked)
    Then a MAIN-THREAD repeating Timer re-issues requestOpenSession() every 2s for ~80s
    And the session opens as soon as I unlock the phone — order no longer matters
    # innards: Importer.tick() phase 1 + the top-level Timer added on the CFRunLoopRun thread.
    # GOTCHA proven live 2026-06-17: a Timer/asyncAfter scheduled from ICC's callback thread
    # never wakes this run loop — it MUST be created on the main thread before CFRunLoopRun().

  @verified
  Scenario: Wait for the NEXT photo, never grab an existing one
    Given the phone holds ~1966 existing photos
    When --watch enumerates them at session open
    Then those are absorbed into the baseline and ignored; only a post-baseline photo is taken
    # innards: catalogReady gate; the baseline diff lives in deviceDidBecomeReady's refresh path.
    # Verified live 2026-06-17 that it correctly WAITS instead of grabbing an old IMG_E####.JPG.

Feature: iPhone photo → the macOS clipboard
  @verified
  Scenario: One command puts a Continuity-grabbed iPhone photo on the pasteboard
    Given I want to paste an iPhone photo straight into Claude / Mail / Messages
    When I run `iphone-clip` (blind Continuity grab)
    Then the captured image is written to the general pasteboard as image data (Cmd-V pastes it)
    # innards: bin/iphone-clip → iphone-photo, then NSImage → NSPasteboard writeObjects.
    # Verified live 2026-06-17: clipboard info shows TIFF/JPEG/PNG picture types. Slash: /iphone-clip.

  @built   # the --watch path inherits the unverified poll-detection above
  Scenario: iphone-clip --watch puts the photo YOU shot on the pasteboard
    Given I run `iphone-clip --watch` and take a photo on the iPhone
    Then that real photo (not a blind grab) is copied to the clipboard
    # innards: bin/iphone-clip --watch → iphone-import --watch (2s poll) → NSPasteboard.
    # @built until a freshly-taken photo is observed landing through the poll.

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
