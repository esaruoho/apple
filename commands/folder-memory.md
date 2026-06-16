---
description: Give a folder a voice — emit the sidecar triad (.memory.md + .memory.savedSearch + .memory.json) auto-formulated from the files' own metadata + on-device embeddings, then talk to / diff / vault / repo it. Apple-native. Usage `/folder-memory <dir> [--chat|--diff|--recursive|--vault <v>|--repo <url>|--show|--open|--no-model]`.
allowed-tools: Bash
argument-hint: <dir> [--chat | --diff | --recursive | --vault <dir> | --repo <url|path> | --show | --open | --no-model | --tag]
---

Run the apple-skill `folder-memory` tool on `$ARGUMENTS`.

Use Bash to execute (one call, then stop):

```
/Users/esaruoho/work/apple/bin/folder-memory $ARGUMENTS
```

It builds, for the target folder:
- `.memory.md` — the understanding (Obsidian node / model context / human-read)
- `.memory.savedSearch` — a live Finder Smart Folder of the load-bearing files
- `.memory.json` — structured snapshot for `--diff`

`--chat` talks to the folder via the Mini's on-device model; `--diff` shows the
vibe diff vs the stored snapshot; `--repo <url>` clones + writes an aggregate
`UNDERSTANDING.md`; `--vault <dir>` folds the notes into an Obsidian vault.
