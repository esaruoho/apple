---
layout: default
title: "Voice Memos `#process` tag + `process` Finder tag + `process` CLI — One Pipeline, Three Front Doors"
---

# Voice Memos `#process` tag + `process` Finder tag + `process` CLI — One Pipeline, Three Front Doors


[← Back to home](./)
Built 2026-05-25. Same shape as the [finder-tag-pipeline](../concepts/finder-tag-pipeline.md) and [stickies-claude-trigger](../concepts/stickies-claude-trigger.md) patterns: a trigger somewhere in the user's normal workflow → Syncthing inbox → Mac Mini worker → result Syncthed home → notification.

## The principle

Any audio or video can become a transcript by stamping the word **process** on it. Three independent front doors all funnel into the same Mini-side worker:

| Front door | Where you tag | What it watches | Built atop |
|---|---|---|---|
| **#process in Voice Memos title** | Voice Memos.app → rename a recording so its title contains `#process` | `AppleToolbox` polls `CloudRecordings.db` every 30 s | `topbar/AppleToolbox.swift :: VoiceMemoPipeline` |
| **`process` Finder tag on any media file** | Finder → tag the file with `process` (Cmd-I or `bin/tag-finder-selection`) | `bin/tag-watcher` mdfind loop, triggered by an existing LaunchAgent | `bin/tag-watcher` `TRIGGERS["process"]` |
| **`process` CLI** | Terminal: `process file.mp3` | direct invocation | `bin/process` → `whisp-submit` |

All three drop a `kind: local_audio` job (audio bytes copied + `.url` sidecar) into the Syncthing-shared `~/work/comms/queue/whisp-inbox/`. The Mac Mini's `whisp-worker` processes it locally (no upload to Apple, no upload to OpenAI — Whisper turbo on the Mini's GPU). The transcript is mirrored back via `~/work/comms/queue/whisp-results/<slug>/` and AppleToolbox fires a clickable `UNUserNotificationCenter` banner.

**No LLM tokens are used in the steady-state loop.** Tag → notification is pure Swift + bash + Syncthing.

## What lives where

| Path | Role |
|---|---|
| `~/work/apple/topbar/AppleToolbox.swift` :: `VoiceMemoPipeline` | Voice Memos title watcher. Runs inside AppleToolbox so it inherits Full Disk Access (required to read the protected `CloudRecordings.db`). Polls every 30 s. Submits + fires "🎙 Sent to whisp" notification on dispatch and "✓ Voice memo transcribed" with click-to-open on arrival. |
| `~/work/apple/topbar/AppleToolbox.swift` :: `NotifyInboxWatcher` | Generic notification renderer. Any peer with Syncthing access to `~/work/comms/queue/notify-inbox/` can drop a JSON file and a native banner appears on this Mac. Used by `whisp-worker`'s boot-time hello. |
| `~/work/apple/bin/process` | Terminal CLI. Forwards args to `whisp-submit`. Resolves relative paths to absolute before handoff. |
| `~/work/apple/bin/tag-watcher` (`TRIGGERS["process"]`) | mdfind for `process`-tagged files, dispatches via `whisp-submit`. Stamps `whisp-queued:yellow` once queued. Companion to `needs-transcription`. |
| `~/work/whisp-transcripts/whisp-submit` | Universal submitter. Auto-detects local file vs URL. Local files: atomic-copy to inbox + write `kind: local_audio` sidecar. URLs: existing YouTube/audio-URL flow. |
| `~/work/whisp-transcripts/whisp-worker` | Mac Mini worker. Handles three kinds: `youtube` (yt-dlp), `audio` (curl), `local_audio` (no download — file already in inbox). Writes transcripts to `whisp-results/<slug>/` which mirrors back via Syncthing. |
| `~/work/comms/queue/whisp-inbox/` | Syncthing-shared queue. Audio bytes + `.url` sidecar arrive here from any of the three front doors. |
| `~/work/comms/queue/whisp-results/<slug>/` | Syncthing-shared output. Contains `transcript.{txt,vtt,srt}` + `metadata.yaml`. AppleToolbox FSEvents-watches this dir for completions. |
| `~/work/comms/queue/notify-inbox/` | Syncthing-shared notification bus. Any peer drops `<id>.json`, AppleToolbox renders it. |
| `~/work/mediabank/state/voicememo-pipeline.state.json` | Dedup state — ZUNIQUEID → submission record. Survives AppleToolbox restarts; never re-submits the same memo. |

## How to use it

### Voice Memos (the easiest)

1. Record a memo on this Mac.
2. Rename it so the title contains `#process` (e.g. `"Tesla coil notes #process #free-energy"`).
3. Within ≤30 s, `VoiceMemoPipeline.tick()` finds it, copies the `.m4a` to `whisp-inbox/`, fires `🎙 Sent to whisp`.
4. Mini transcribes it; when the result file appears via Syncthing, `✓ Voice memo transcribed` banner fires. Click → opens the transcript. Alt-action: **Reveal in Finder**.

### Any media file from Finder

1. Right-click the file → Tags… → type `process`.
2. The LaunchAgent-driven `tag-watcher` mdfind loop sees the new tag, dispatches via `whisp-submit`, stamps `whisp-queued:yellow`.
3. Mini processes; transcript appears in `~/work/whisp-transcripts/transcripts/<date>_<slug>/` (the URL-style outputs) AND mirrored via Syncthing in `whisp-results/<slug>/`.

### From the terminal

```
process /path/to/recording.mp4
process *.mp3
process https://www.youtube.com/watch?v=…    # URLs still work
process file.m4a https://… file2.wav         # mix freely
```

## The Tier-1 contract on the worker side

The Mini's `whisp-worker` was upgraded with a `local_audio` branch (commit `36a9557`):

```
intake_from_comms_inbox():
  for each *.url in whisp-inbox/:
    if kind == "local_audio":
      if not file_at(path:) yet:           # Syncthing may have delivered .url before .m4a
        skip — try again next tick
      else:
        move .url to PENDING

process_url_file():
  if kind == "local_audio":
    copy path: → workdir/  (safe: never moves the Syncthing-shared file)
    run whisp on workdir/copy
    archive_audio() moves the workdir copy to CLOUDCITY4TB
    after success: delete inbox copy (Syncthing reclaims space on Mac X too)
```

The "wait for the .m4a before moving the .url" guard matters: Syncthing's delivery order is unordered, so the worker can see the `.url` before the audio file arrives. Without this, the worker would try to process a non-existent file and fail.

## Why every front door funnels into one inbox

Three separate code paths (Swift watcher / bash tag-watcher / bash CLI) all converge on `whisp-inbox/`. From the worker's perspective, every job looks the same — there is exactly one `kind: local_audio` contract. New front doors (e.g. a Shortcut, a Loupedeck button, a webhook) just need to land their file + `.url` sidecar in the same inbox. **No worker changes required to add a new trigger surface.**

This is the same pattern as `finder-tag-pipeline.md`: the dispatch shape is the invariant, the trigger is the variable.

## Notifications (zero-token confirmation channel)

AppleToolbox is the universal renderer:

1. `VoiceMemoPipeline` itself emits "🎙 Sent to whisp" on dispatch and "✓ Voice memo transcribed" on result arrival. The latter carries `transcript_path` in `userInfo`; the `VOICEMEMO_TRANSCRIBED` category has **Open** and **Reveal in Finder** actions.
2. `NotifyInboxWatcher` renders any JSON dropped into `~/work/comms/queue/notify-inbox/` from any peer. Schema: `{title, subtitle?, body?, sender, open_path?, reveal_path?}`. Used by `whisp-worker`'s boot ping (`🎙 Whisp worker online on <minihostname>`).
3. Both routes are dispatched by a single `NotificationRouter` (UNUserNotificationCenter only allows one delegate; the router fans out by `categoryIdentifier`).

Companion helper for any peer to drop a notification request: `~/work/mediabank/bin/cloudcity-notify "Title" "Body"`.

## Critical gotcha that cost hours

`ZCUSTOMLABEL` in `CloudRecordings.db` is NOT the user's renamed title — that's an internal ISO timestamp string. The renamed title lives in `ZENCRYPTEDTITLE` (plaintext despite the name) and `ZCUSTOMLABELFORSORTING`. Searching `ZCUSTOMLABEL` for `#process` silently returns zero rows for any renamed memo.

Full write-up: `concepts/voice-memos-zencryptedtitle-holds-renamed-title.md`.

## Related

- `concepts/finder-tag-pipeline.md` — the original tag → Mac Mini pattern (PDFs → OCR).
- `concepts/stickies-claude-trigger.md` — the same shape for Stickies notes.
- `concepts/voice-memos-tsrp-atom.md` — Apple's native auto-transcripts (poor on Finnish; we use Whisper instead).
- `concepts/voice-memos-zencryptedtitle-holds-renamed-title.md` — the column-naming trap that broke the first build.
- `entities/appletoolbox.md` — the menu-bar host process.

## Status & dates

- 2026-05-25 — built end-to-end. AppleToolbox `VoiceMemoPipeline` running; `whisp-submit` accepts local files; `tag-watcher` recognises `process`; `bin/process` CLI lives in `~/work/apple/bin/`. First real memo (`Ruoho-Gasik-Kortela talk 1 #process`) submitted at 12:48:09Z, transcript pending Mini pickup at time of writing.
