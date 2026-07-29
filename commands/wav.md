---
description: Arrow-key picker for capturing one app's audio to a .wav. Lists every app, marks the ones actually making sound right now with ●, Enter records. No plugin, no BlackHole, no reroute.
allowed-tools: Bash
argument-hint: (none) | --seconds N | --out <folder> | --all-procs
---

Run the apple-skill `wav` picker on `$ARGUMENTS`.

Use Bash to execute (one call, then stop):

```
/Users/esaruoho/work/apple/bin/wav $ARGUMENTS
```

- `/wav` — pick with ↑/↓, Enter records until Ctrl-C
- `/wav --seconds 20` — Enter records exactly 20 s
- `/wav --out ~/Music/grabs` — where the .wav lands (folder created if missing)
- `/wav --then "Ableton"` — record, then open the .wav in that app ("first, then")
- `/wav --then finder` / `--then none` — reveal it, or just leave it

Keys inside the picker: `↑↓`/`kj` move · `Enter` record · `a` all system audio ·
`p` playing-only · `+`/`-` duration ±5 s · `q` quit.

`●` = that app is outputting audio right now (CoreAudio process objects, macOS 14.4+).
Non-interactive sibling: `/app-audio-record --app <name>`.
