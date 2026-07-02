---
description: Post-process a rec recording's audio for editing. `split` extracts the system-audio and mic tracks to separate .m4a sidecars (drop into iMovie as independent tracks). `flatten` mixes them into one track on a video-passthrough .mov (plays both everywhere). Apple-native AVFoundation.
allowed-tools: Bash
argument-hint: split <recording.mov> | flatten <recording.mov> [-o out.mov]
---

Run the apple-skill `rec-audio` tool on `$ARGUMENTS`.

Use Bash to execute (one call, then stop):

```
/Users/esaruoho/work/apple/bin/rec-audio $ARGUMENTS
```

- `/rec-audio split <recording.mov>` → `<stem>-system.m4a` + `<stem>-mic.m4a`.
  **iMovie recipe:** import the `.mov` for the video (it carries the system audio), then drag
  `<stem>-mic.m4a` onto the timeline as a second audio track — now you can balance voice vs
  app sound, mute either, ripple-trim independently. iMovie can't split embedded tracks out of
  one file, which is why these sidecars exist.
- `/rec-audio flatten <recording.mov> [-o out.mov]` → `<stem>-flat.mov`: video (passthrough,
  no re-encode) + ONE mixed audio track (system+mic summed, each attenuated to 0.8 to avoid
  clipping). Plays both everywhere — QuickTime, iMovie, YouTube.

After the command completes, report only the lines it printed.
