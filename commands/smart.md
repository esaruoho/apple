---
description: Throwaway Smart Folder. Generates a .savedSearch in /tmp and opens it in Finder. Usage `/smart <path>`, `/smart <path> <preset>`, `/smart <path> --query "<mdfind>"`, or `/smart --from <markdown-file> [scope]` to view only the images referenced by that wiki page.
allowed-tools: Bash
argument-hint: <path> [preset|--query "<expr>"] | --from <md-file> [scope]
---

Run the apple-skill `smart` wrapper on `$ARGUMENTS` — generates a one-shot Smart Folder, opens it in Finder. Re-run any time for a fresh view.

Use Bash to execute (one call, then stop):

```
/Users/esaruoho/work/apple/bin/smart $ARGUMENTS
```

Modes:
- **Scope + preset** — `/smart ~/Downloads pdfs`. Presets: `images` (default), `pdfs`, `audio`, `video`, `docs`, `recent` (last 7d), `big` (>100 MB).
- **Raw mdfind** — `/smart ~ --query 'kMDItemPixelHeight > 2000'`.
- **Wiki mode** — `/smart --from ~/wiki/MyPage.md` shows only images that the markdown references (parses `![[wikilinks]]`, `![](paths)`, `<img src>`). Scope defaults to the file's directory; pass a second arg to override.

After the command completes, report only the path it printed. Do not summarize results.
