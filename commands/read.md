---
description: Read the macOS clipboard aloud via local Voicebox (Kokoro). Uses a voice distinct from Claude's chat-speak so the two don't blur. Select text → Cmd-C → `/read`. Stop with `/read --stop`. Usage `/read`, `/read --grab`, `/read --text "..."`, `/read --stop`.
allowed-tools: Bash
argument-hint: (no args) | --grab | --stop | --text "<literal>" | --profile <voice>
---

Run the apple-skill `read-aloud` wrapper on `$ARGUMENTS` — speaks the current clipboard via Voicebox at `localhost:17493`, plays through default audio out, returns immediately. Re-invoking cancels the previous reading.

Use Bash to execute (one call, then stop):

```
/Users/esaruoho/work/apple/bin/read-aloud $ARGUMENTS
```

Modes:
- **`/read`** — speak whatever's currently on the clipboard.
- **`/read --grab`** — synthesize Cmd-C first so the active selection lands on the clipboard, then speak it (needs Accessibility permission, prompted once).
- **`/read --text "literal text"`** — speak a string directly, skip the clipboard.
- **`/read --stop`** — kill the in-flight reading.
- **`/read --profile <voice>`** — override the voice for one call.

After the command completes, report only the lines the script printed. Do not summarize or transcribe the audio.
