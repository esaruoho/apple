---
description: Emit a newline-separated list of Sal's Siri command phrases (588 entries) + user's own Shortcuts. Used by the "Hey Sal" picker. Usage `/siri-phrases`.
allowed-tools: Bash
argument-hint: (no arguments)
---

Dump the full Sal-Siri phrase list (Sal commands + user Shortcuts) for picker / fuzzy-match consumption.

Use Bash to execute (one call, then stop):

```
/Users/esaruoho/work/apple/bin/sal-siri-list-phrases.py
```

After the command completes, report counts (Sal phrases, user shortcuts) — not the whole list.
