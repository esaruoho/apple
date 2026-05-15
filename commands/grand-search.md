---
description: Unified ripgrep search across every Apple bulk-exporter vault (mail, safari, notes, imessage, voice memos, etc.). Usage `/grand-search <query>`.
allowed-tools: Bash
argument-hint: "<query>" [--only A,B,C] [--case-sensitive]
---

Search every exporter vault under `~/work/apple/exported/`. Deterministic, no LLM filtering.

Use Bash to execute (one call, then stop):

```
/Users/esaruoho/work/apple/bin/apple-grand-search $ARGUMENTS
```

After the command completes, report hits verbatim. Do not editorialize.
