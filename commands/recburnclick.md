---
description: Screen + system-audio recording with a live "CLICKS: n" counter burned into the video. Counts every mouse-down from the moment recording starts. No Accessibility permission, no event tap.
allowed-tools: Bash
argument-hint: (none) | --clicks-corner tl|tr|bl|br | --clicks-label TAPS | --mic | --pip | --app <name>
---

Run the apple-skill `recburnclick` recorder on `$ARGUMENTS`.

Use Bash to execute (one call, then stop):

```
/Users/esaruoho/work/apple/bin/recburnclick $ARGUMENTS
```

- `/recburnclick` — everything `recburn` does (screen + system audio + **mic** + webcam
  circle + subtitles on stop) **plus** the click counter → `./<timestamp>.mov`
- `/recburnclick --clicks-corner br` — move the badge (default top-left)
- `/recburnclick --clicks-label TAPS` — relabel the counter
- `/recburnclick --no-pip` — drop the webcam, keep mic + subtitles + clicks
- `/recburnclick --no-mic --no-burn` — subtract anything recburn added
- `/recburnclick --app Renoise` — only that app's audio, still counting clicks

Ctrl-C stops and finalizes. This is `recburn` plus `--clicks`, so it inherits recburn's
settings (mic, webcam, subtitles); `--no-mic` / `--no-pip` / `--no-burn` subtract them.
Also a RecBurn.app menu setting: **Click Counter** + **Click Counter Position**. The count comes from macOS's own per-session mouse-down tally
(`CGEventSource.counterForEventType`), so there is no event tap and no permission prompt.
