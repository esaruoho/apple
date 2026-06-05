# Sensor Snapshot — every camera + iPhone screen + every audio input, to files

description: Apple-native automated snapshot of this Mac's (and a tethered iPhone's) sensors — all cameras, the iPhone screen, and N audio snippets per input — fired by one `snapshot` command into a timestamped folder. Plus the AVCapture KVO landmine that shapes the whole design.

Package: `sensor-snapshot/` → faceless `Snapshot.app` bundle (4 binaries) + `bin/{snapshot,iphone-photo,iphone-import,audio-snippets,iphone-screen}`. Report card: [`sensor-snapshot/snapshot.feature`](../../sensor-snapshot/snapshot.feature).

## The one command

```bash
snapshot [<dir>] [--quick] [--per-channel] [--no-audio] [--no-screen]
```

Produces `snapshot-<timestamp>/` with `cameras/`, `screen/`, `audio/`, and `manifest.md`. Missing sensors (locked phone) are logged in the manifest, never fatal.

## The four capture paths

| Sensor | Tool | Mechanism | Ceiling |
|---|---|---|---|
| Every camera | `iphone-photo --all <dir>` | AVFoundation `DiscoverySession` → frame-grab each | device-native |
| iPhone rear camera | `iphone-photo` | Continuity Camera (`.continuityCamera`) | **~2.8MP** |
| iPhone full-res photo | `iphone-import --latest\|--watch` | ImageCaptureCore (PTP over USB) | 12/48MP |
| iPhone screen | `iphone-screen` | CoreMediaIO screen-capture DAL + frame-grab | screen-native |
| Every audio input | `audio-snippets <dir> [--per-channel]` | AVCaptureSession + AVCaptureAudioFileOutput | all channels |

## THE landmine: AVCapture*Output + KVO in a swiftc binary

`AVCapturePhotoOutput` and `AVCaptureFileOutput` register KVO observers on themselves at runtime (`NSKVONotifying_*`). A `swiftc` command-line binary **cannot synthesize those dynamic subclasses** — and, contrary to first intuition, **hosting the binary inside a `.app` bundle does NOT fix it.** Symptom: the capture/recording delegate callback **never fires** → silent timeout, even though the file may have been written.

Design consequence — avoid the delegate entirely:
- **Cameras / screen:** use `AVCaptureVideoDataOutput` (raw sample buffers, no KVO); convert one buffer → JPEG via `CGImageDestination`.
- **Audio:** still use `AVCaptureAudioFileOutput` (it records fine), but **don't trust `didFinishRecordingTo`** — after `stopRecording()`, **poll the output file** until `AVAudioFile(forReading:)` opens it with `length > 0`.

This is the reusable gotcha: *if an AVCapture output's completion is a delegate that depends on KVO, it won't fire in a swiftc tool — design around it.*

## Why the bundle exists anyway (two real reasons, not KVO)

1. **`NSCameraUseContinuityCameraDeviceType`** must be in `Bundle.main`'s Info.plist or AVFoundation won't even *enumerate* the iPhone as a Continuity Camera (a bare CLI logs `WARNING: Add NSCameraUseContinuityCameraDeviceType…`). Verified: same binary run from inside `Snapshot.app` sees it; run bare, it doesn't.
2. **Stable TCC identity** — the bundle (id `com.esaruoho.apple.snapshot`) holds the Camera + Microphone grants across rebuilds. Wrappers `exec` the in-bundle binary so `Bundle.main` resolves to the `.app`.

## Hard limits (verified, not guessed)

- **Continuity Camera = rear only.** No front-camera position/device is exposed to the Mac. A front-camera capture would need software running *on* the iPhone + a tap → banned by the no-UI-hijack rule. **Architecturally impossible from the Mac.**
- **Continuity still caps at ~2.8MP** (1920×1440), so `AVCapturePhotoOutput`'s higher-res still buys nothing here — another reason the frame-grab path wins.
- **Full-res import + screen capture both need the iPhone unlocked AND trusted** ("Trust This Computer"). ImageCaptureCore reports an untrusted/locked device as `Code=-9943 "Please unlock"`; the CoreMediaIO screen device simply doesn't enumerate. Code is correct; these are physical-state gates.

## Per-channel audio split

`--per-channel` records each device's full multichannel stream, then `AVAudioFile` reads it into a deinterleaved float buffer and writes each channel as its own mono `.caf`. Verified: CalDigit 2ch→2 files, the 7-channel Aggregate → 7 files.

## Related

- [`global-keyboard-shortcuts.md`](global-keyboard-shortcuts.md) — could trigger `snapshot` from a hotkey.
- [`mail-flag-pipeline.md`](mail-flag-pipeline.md) — same trigger→worker chassis family.
- Report card + session: [`sensor-snapshot/snapshot.feature`](../../sensor-snapshot/snapshot.feature), [`snapshot.session.md`](../../sensor-snapshot/snapshot.session.md).
