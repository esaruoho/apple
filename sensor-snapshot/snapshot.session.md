# Session — Sensor Snapshot (spawning conversation)

Faithful, not flattering. This is the grade's audit trail for `snapshot.feature`.

## How to get back
- Transcript: `file:///Users/esaruoho/.claude/projects/-Users-esaruoho-work-apple/c3e2bcb9-53e2-43c5-8efc-1d0f12a6b08d.jsonl`
- Session ID: `c3e2bcb9-53e2-43c5-8efc-1d0f12a6b08d`
- Resume: `claude --resume c3e2bcb9-53e2-43c5-8efc-1d0f12a6b08d`
- Dates: built 2026-06-04 → 2026-06-05 (EEST).

## The asks, in order
1. "iPhone connected to laptop → programmatically take a photo → photo shows on the computer as a file."
2. "Programmatically screenshot the iPhone screen AND photo from front + rear cameras — a truly automated snapshot."
3. "5 snippets of sound from every audio input channel?"
4. Chosen next step: build the umbrella `snapshot` command (+ rename package to `sensor-snapshot/`).

## Forks the user decided (AskUserQuestion)
- Connection: **USB-tethered**. Quality: **full-res** → forced the honest reconciliation below.
- Given 48MP-into-Photos is impossible from the Mac: **build both** (programmatic ~12MP Continuity still + tap-then-import full-res).
- Audio scope: **both/runtime** (`--per-channel` flag). Timing: **5×3s spread ~30s**.
- Next: **build the umbrella `snapshot`**.

## Honest "no"s and corrections I had to make (not flattering)
- **Front iPhone camera from the Mac: impossible.** Continuity exposes only the rear system. Said so plainly rather than hand-waving a workaround.
- **Full-res 48MP-into-Photos triggered from the Mac: impossible** Apple-native without a UI-hijack tap. The reframe: the iPhone's *default* photo is 12MP, and Continuity stills cap at ~2.8MP — so "full-res webcam still" ≠ "full-res Camera.app photo".
- **My bundle hypothesis was WRONG.** I claimed hosting in a `.app` bundle would fix `AVCapturePhotoOutput`'s `NSKVONotifying_*` KVO failure. It did not — the delegate still never fired. Switched to `AVCaptureVideoDataOutput` (the proven frame-grab). Same landmine bit `AVCaptureAudioFileOutput` later → worked around by polling the output file instead of trusting `didFinishRecordingTo`.
- **maxStill probe corrected my own estimate** from "~12MP" down to the real **2.8MP** Continuity ceiling once the phone enumerated.

## Bugs found + fixed live
- `maxPhotoDimensions = 640x480` then format-mismatch crash → select highest-res `activeFormat`; then live re-negotiation on `startRunning` → recompute dims at capture time. (Ultimately moot: dropped PhotoOutput entirely.)
- `.inputPriority` unavailable on macOS → rely on `activeFormat` auto-flipping the preset.
- ImageCaptureCore conformance: missing required delegate methods, separate `ICCameraDeviceDownloadDelegate`, `ICSavedFilename` → `ICDownloadOption.savedFilename.rawValue`.
- `availableOutputFileTypes` is a class method, not a property.

## Still gated on physical phone state (not code)
- `iphone-import` full-res: blocked on "Please unlock" (DCIM gate).
- `iphone-screen`: CoreMediaIO enable returns status=0 but the screen device only enumerates when the phone is awake + trusted; not yet seen green.
