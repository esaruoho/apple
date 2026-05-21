---
description: Open a Smart Folder for a known concept (Schauberger, Tesla, Russell, etc.) and speak a caption via Voicebox. Zero LLM in the hot path — dict lookup + .savedSearch + local Kokoro TTS. Usage `/show <concept>`, `/show --list`, or `/show --add <key> <path> [name]`.
allowed-tools: Bash
argument-hint: <concept> | --list | --add <key> <path> [name]
---

Run the apple-skill `show` wrapper on `$ARGUMENTS` — dictionary lookup against `concepts.json`, opens a Smart Folder in Finder, speaks the caption via the local Voicebox (silent if Voicebox isn't running).

Use Bash to execute (one call, then stop):

```
/Users/esaruoho/work/apple/bin/show $ARGUMENTS
```

Modes:
- **`/show schauberger`** — opens the Schauberger image archive, speaks "Viktor Schauberger archive. N items. Opening now."
- **`/show --list`** — print every known concept and whether its scope still exists.
- **`/show --add lenr-academy ~/work/lenr-academy "LENR Academy"`** — register a new concept and immediately open it.

The concept index lives at `~/work/apple/concepts.json` — hand-editable. After the command completes, report only the lines the script printed. Do not summarize the archive.
