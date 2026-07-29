# Session — app-audio-record (tap one app's audio to a .wav)

Card: [`features/app-audio-record.feature`](app-audio-record.feature)
Innards: `bin/app-audio-record.swift`, `commands/app-audio-record.md`

## How to get back

- Transcript: `file:///Users/esaruoho/.claude/projects/-Users-esaruoho-work-apple/00cf1a54-2fe3-4be0-ac2a-5ffd17bd5630.jsonl`
- Session ID: `00cf1a54-2fe3-4be0-ac2a-5ffd17bd5630`
- Resume: `claude --resume 00cf1a54-2fe3-4be0-ac2a-5ffd17bd5630`
- Date: 2026-07-29, ~13:10–13:20 EEST (Helsinki), cwd `/Users/esaruoho/work/apple`
- Machine: macOS 15.6.1 (24G90)

## The request (verbatim)

> recburn. i wanna know. can we create a patcher that basically is a plugin that receives
> audio from a diffferent app. an audiounit plugin that is basically just "hear to virtual
> output port .. this audio" and then it comes to the track. i was hoping to be able to just
> record a wavefile to a specific folder by just .. getting it from a source audio. can we
> accomplish that somehow so that an app can be playing audio, and we can capture that apps
> audio as wavefile briefly.

## The correction I made to the framing

The AudioUnit shape was rejected up front, with the reason stated rather than softened:
an AU is loaded *into* a host process and has no route to another application's audio.
The only thing that shape buys is a loopback HAL driver (BlackHole / Loopback /
Soundflower) — an install, plus a manual re-point of the source app's output device.

The goal underneath the framing ("an app is playing audio, capture that app's audio as a
wavefile briefly") is exactly what ScreenCaptureKit already does, and what this repo was
*already* doing for video: `bin/screen-audio-record --app Renoise` captures only that
app's audio. What was missing was the audio-only, straight-to-WAV variant. So: keep the
goal, drop the mechanism.

## Decisions

- **New tool, not a flag on screen-audio-record.** That file is 684 lines and structurally
  video-first (writer, PiP compositor, camera, subtitle burn, manifest). The genuinely
  shared part is ~10 lines of app-matching. A separate ~230-line audio-only tool is the
  honest split; the DRY unit here is the *pattern*, not the code.
- **AVAssetWriter with fileType `.wav`** rather than hand-rolling ExtAudioFile or
  converting CMSampleBuffer → AVAudioPCMBuffer by hand. SCK delivers Float32; the writer's
  AudioConverter does the 16-bit interleaved conversion. Verified by `afinfo`, not assumed.
- **`--seconds N`** because the ask was explicitly "briefly" — a timed capture shouldn't
  require a Ctrl-C.
- **Default output = cwd**, matching `rec`'s convention (changed to cwd in that tool's
  Ship 3), not `~/Movies` / `~/Music`.
- **CoreAudio process taps (macOS 14.4+) considered and not taken** — leaner and avoids
  the Screen Recording prompt, but SCK was already proven in-repo. Recorded on the card as
  the named swap if the permission ever bites.

## Verification actually performed (not inferred)

1. Built with `swiftc -O`; two compile errors fixed (a `.map` closure arity error on the
   scope label, a bogus `??` on a non-optional Int).
2. `--list` → real app list (Live, Schism Tracker, Safari, …).
3. **Positive:** `--all --seconds 4` while `afplay -v 0.05 Submarine.aiff` played →
   `afinfo`: WAVE, 2 ch, 48000 Hz, Int16, 4.26 s; sample analysis: peak 5281, RMS 1602.
4. **Negative control:** `--app Preview --seconds 4` with the *same* sound audibly playing
   → peak 0, RMS 0. This is the scenario that actually proves per-app scoping; without it,
   test 3 alone would only prove "a WAV got written".

The Ctrl-C branch is graded `@built`, not `@hw-verified` — the timed path exercises the
same `finish()`, but interactive SIGINT delivery was not run in this session.

## Side effects surfaced

- Test audio was played on Esa's machine at volume 0.05 (near-inaudible) rather than full
  volume, and only the built-in Submarine sound.
- Test artifacts went to the session scratchpad, not into the repo.
