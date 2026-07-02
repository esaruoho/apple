---
description: Record the screen AND audio straight off the system audio engine — no microphone, no loopback driver (BlackHole/Loopback), no virtual cable. Scope the audio to a single app (e.g. Renoise) or grab all system audio. Apple-native ScreenCaptureKit. Ctrl-C stops and finalizes the .mov.
allowed-tools: Bash
argument-hint: --list | --app <name> --out <path> | --system-audio --out <path> [--also-mic] [--fps N]
---

Run the apple-skill `screen-audio-record` recorder on `$ARGUMENTS`.

Use Bash to execute (one call, then stop):

```
/Users/esaruoho/work/apple/bin/screen-audio-record $ARGUMENTS
```

Modes:
- `/screen-audio-record --list` — list displays + audible running apps, then exit
- `/screen-audio-record --app Renoise --out ~/rec.mov` — screen + ONLY that app's audio
- `/screen-audio-record --system-audio --out ~/rec.mov` — whole display + ALL system audio
- `/screen-audio-record --app Renoise --mic --out ~/rec.mov` — + your mic as a 2nd track
- `/screen-audio-record --system-audio --reveal` — reveal the finished file in Finder
- `--display <n>` picks a display from `--list`; `--fps <n>` sets frame rate (default 60)

Press **Ctrl-C** to stop and finalize the file. Toggle the mic on/off mid-recording with
`kill -USR1 <pid>`. No BlackHole/Loopback needed — audio comes straight off the system audio
engine via ScreenCaptureKit. Sequoia re-prompts screen-recording permission weekly / after
reboot; approve iTerm once when asked.

After the command completes, report only the lines it printed.
