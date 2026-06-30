---
description: Read macOS energy/power from the CLI — the Activity Monitor "Energy" tab via Apple-shipped tools (powermetrics, top, system_profiler, pmset). Snapshot apps by energy impact, sample+rank over time, system watts, or adapter wattage. Usage `/apple-energy [now [N] | watch [mins] [secs] | power [N] | adapter | help]`.
allowed-tools: Bash
argument-hint: [now [N] | watch [mins] [secs] | power [N] | adapter | help]
---

Run the apple-skill `apple-energy` wrapper on `$ARGUMENTS`.

Use Bash to execute (one call, then stop):

```
/Users/esaruoho/work/apple/bin/apple-energy $ARGUMENTS
```
