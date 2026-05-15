---
description: Regenerate scripts.md from the 186-recipe workflow-gen catalog (always in sync). Usage `/workflow-catalog`.
allowed-tools: Bash
argument-hint: (no arguments)
---

Auto-generate `scripts.md` from the workflow-gen recipe catalog.

Use Bash to execute (one call, then stop):

```
cd /Users/esaruoho/work/apple && python3 bin/workflow-gen.py --catalog
```

After the command completes, report only the path and recipe count.
