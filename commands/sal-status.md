---
description: Refresh and read the Sal archive dashboard. Pure regen, no LLM analysis. Usage `/sal-status`.
allowed-tools: Bash
argument-hint: (no arguments)
---

Refresh the Sal archive status dashboard. Deterministic, no roundtrip.

Use Bash to execute (one call, then stop):

```
python3 /Users/esaruoho/work/apple/bin/sal-archive-status.py --write /Users/esaruoho/work/apple/analysis/sal/current-status.md && cat /Users/esaruoho/work/apple/analysis/sal/current-status.md
```

After the command completes, report the dashboard verbatim. Do not summarize, re-interpret, or moralize about archive completeness.
