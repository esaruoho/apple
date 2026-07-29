---
description: Capture ONE app's audio straight to a .wav — no AudioUnit plugin, no BlackHole/Loopback, no reroute. ScreenCaptureKit taps the app's audio in parallel while it keeps playing normally.
allowed-tools: Bash
argument-hint: --list | --app <name> [--seconds N] [--out file.wav] | --all
---

Run the apple-skill `app-audio-record` tool on `$ARGUMENTS`.

Use Bash to execute (one call, then stop):

```
/Users/esaruoho/work/apple/bin/app-audio-record $ARGUMENTS
```

- `/app-audio-record --list` — which apps can be tapped
- `/app-audio-record --app Live --seconds 10` — 10s of Ableton Live → `./<stamp>-Live.wav`
- `/app-audio-record --app Renoise --out ~/take.wav` — runs until Ctrl-C
- `/app-audio-record --all --seconds 5` — all system audio

Audio-only sibling of `/rec` (which records screen + audio to .mov). Output is
48 kHz / 16-bit / stereo LinearPCM WAV. Needs Screen Recording permission.
