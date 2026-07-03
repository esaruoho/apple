---
description: One-word screen + system-audio recorder. Starts immediately — whole screen + ALL system audio → ~/Videos/yyyy-MM-dd-HH-mm-ss.mov. No mic, no BlackHole/Loopback (audio off the system engine via ScreenCaptureKit). Ctrl-C stops + finalizes.
allowed-tools: Bash
argument-hint: (none) | --app <name> | --also-mic | --out <path> | --list
---

Run the apple-skill `rec` launcher on `$ARGUMENTS`.

Use Bash to execute (one call, then stop):

```
/Users/esaruoho/work/apple/bin/rec $ARGUMENTS
```

- `/rec` — whole screen + all system audio → `./<timestamp>.mov` (current folder)
- `/rec --app Renoise` — screen + ONLY that app's audio
- `/rec --mic` — start with the microphone recording too (2nd track) + auto YouTube -flat.mov
- `/rec --pip` — bake the webcam in as a **circle** in the corner (speaking head)
- `/rec --mic --pip --burn` — the whole pipeline in one command: record → flatten →
  transcribe (on the Mini) → burn subtitles → `-subtitled.mov` (add `--burn-local` to
  transcribe on this mac instead)
- `/rec --reveal` — reveal + select the finished file in Finder
- `/rec --pip-square` / `--pip-corner tl|tr|bl|br` / `--pip-scale 0.16` — PiP tweaks
- `/rec --out ~/foo.mov` — custom path · `/rec --list` — displays + audible app names

Press **Ctrl-C** to stop and finalize. Toggle the **mic on/off mid-recording** with
`kill -USR1 $(pgrep -n screen-audio-record)`. Thin wrapper over
`bin/screen-audio-record --system-audio`; `--app` overrides (single-app audio wins).
Same recorder the AppleToolbox 🧰 ▸ **Record Screen & Audio** toggle (⌃⌥⌘R) drives —
there the mic live-toggle is ⌃⌥⌘M and files land in `~/Movies`.

After the command completes, report only the lines it printed.
