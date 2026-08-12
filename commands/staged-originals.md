---
description: Find the full-quality photo/video originals Messages kept when it downscaled what you sent — usually your only copy, invisible to every Apple UI.
---

Run `bin/messages-staged-originals` with any arguments the user gave, from the apple repo.

Send a file too big for iMessage and Messages compresses a copy, sends that, and keeps
YOUR original on disk attached to the same message. `attachment.total_bytes` records the
*transmitted* size, so the original is under-reported everywhere and rendered nowhere.

Report what it prints. Key points to surface:

- **Tiers A+B are the user's originals.** The other party holds the compressed copy.
  These are frequently the only full-quality version in existence.
- **They die silently** to `Keep messages ▸ 1 Year` or a whole-conversation delete.
  Always mention rescue before mentioning any deletion.
- Only tier A is proven (a companion's real size equals the row's `total_bytes`).
  Tier B is likely, C is unproven, D is incoming — never auto-delete C or D.

Common invocations:

```bash
bin/messages-staged-originals                          # tiered summary
bin/messages-staged-originals --tier B --min-mb 40     # the big ones
bin/messages-staged-originals --rescue ~/Desktop/originals
bin/messages-staged-originals --delete-proven          # tier A only, to Trash
```

Background: `wiki/concepts/messages-attachment-store.md`, painpoint SYSTEM-SETTINGS-002.
