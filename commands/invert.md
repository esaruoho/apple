---
description: Invert dark-mode image or folder of images to light-mode (non-destructive). Opens output. Usage `/invert <path>` or `/invert <path> [gamma] [contrast]`.
allowed-tools: Bash
argument-hint: <path-to-file-or-folder> [gamma=6.0] [contrast=2.0]
---

Run the apple-skill `invert` wrapper on `$ARGUMENTS` — non-destructive, opens output, no roundtrip.

Use Bash to execute (one call, then stop):

```
/Users/esaruoho/work/apple/bin/invert $ARGUMENTS
```

Behaviour:
- File input → writes `<name>_inverted.<ext>` next to the original, reveals it in Finder.
- Folder input → writes to a sibling `<dir>_inverted/`, opens that folder.
- Originals are never modified.
- Defaults: gamma=6.0, contrast=2.0 (tuned for Kindle dark mode). Pass extra args to override: `/invert ~/Pictures/foo 4.0 1.5`.

After the command completes, report only the output path printed by the script. Do not re-process or re-invert.
