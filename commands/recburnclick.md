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

- `/recburnclick` — whole screen + all system audio + click counter → `./<timestamp>.mov`
- `/recburnclick --clicks-corner br` — move the badge (default top-left)
- `/recburnclick --clicks-label TAPS` — relabel the counter
- `/recburnclick --mic --pip` — the full speaking-head demo, counting clicks
- `/recburnclick --app Renoise` — only that app's audio, still counting clicks

Ctrl-C stops and finalizes. Everything `rec` accepts works here too — this is `rec`
plus `--clicks`. The count comes from macOS's own per-session mouse-down tally
(`CGEventSource.counterForEventType`), so there is no event tap and no permission prompt.
