---
description: Submit text for TTS via Syncthing to the Mac Mini's Voicebox. Drops a job into ~/work/comms/queue/voicebox-inbox/, worker on Mini synthesises, WAV returns to voicebox-results/. Usage `/voicebox-submit <file>`, `/voicebox-submit --text "..."`, `/voicebox-submit --status`, `/voicebox-submit --wait <file>`.
allowed-tools: Bash
argument-hint: <file> | --text "<literal>" | --wait <file> | --status | --list-results | --id <slug> --text "..."
---

Run the apple-skill `voicebox-submit` wrapper on `$ARGUMENTS` — Syncthing carries the job to CloudcityMacMini's voicebox-worker, the worker hits local Voicebox, the WAV returns via Syncthing.

Use Bash to execute (one call, then stop):

```
/Users/esaruoho/work/apple/bin/voicebox-submit $ARGUMENTS
```

Modes:
- **`/voicebox-submit ~/path/to/passage.md`** — submit a file's contents.
- **`/voicebox-submit --text "Hello world"`** — submit literal text.
- **`/voicebox-submit --id schauberger-water-spiral-01 --text "..."`** — content-addressed clip. Same id always returns the same WAV, replayable forever; cached hits open the existing WAV instantly without re-queueing.
- **`/voicebox-submit --wait <file>`** — submit and block until the WAV arrives, then open it.
- **`/voicebox-submit --profile Bella <file>`** / `--engine kokoro` — override voice / engine.
- **`/voicebox-submit --status`** — show inbox / results counts + worker heartbeat age.
- **`/voicebox-submit --list-results`** — list completed WAVs by recency.

After the command completes, report only the lines the script printed. Do not transcribe audio.
