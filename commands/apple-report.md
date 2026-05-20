---
description: Full Mac capability report (CPU/GPU/RAM/SSD/security/power) + AI-workload assessment ("can I run this model?"). Apple-native. Usage `/apple-report`, `/apple-report --ai`, `/apple-report --can-run "70b q4"`, `/apple-report --json`.
allowed-tools: Bash
argument-hint: [--ai] [--json] [--md] [--can-run "<spec>"]
---

Produce a complete capability report for this Mac. Deterministic — no LLM analysis after the run.

Use Bash to execute (one call, then stop):

```
/Users/esaruoho/work/apple/bin/apple-report $ARGUMENTS
```

After the command completes, print the output verbatim. Do not editorialize, summarize, or moralize about whether the machine is "enough". The report already answers that question via the AI-workload section and `--can-run` verdicts.
