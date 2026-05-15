---
description: Run every Apple bulk exporter in one pass (notes, mail, safari, imessage, voice memos, etc.). Usage `/grand-export` or `/grand-export --quick`.
allowed-tools: Bash
argument-hint: [--quick] [--only A,B,C] [--skip A,B,C] [--dry-run]
---

Run every bulk exporter sequentially. Each writes to `~/work/apple/exported/<name>/`.

Use Bash to execute (one call, then stop):

```
/Users/esaruoho/work/apple/bin/apple-grand-export $ARGUMENTS
```

After the command completes, report the summary table verbatim.
