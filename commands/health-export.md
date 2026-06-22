---
description: Turn an Apple Health `export.zip` (made on iPhone via Health ▸ profile ▸ Export All Health Data) into per-metric CSVs, per-day aggregates, a summary.md and manifest.json. Pure Python stdlib, streams huge files. Usage `/health-export <export.zip|export.xml|dir> [--list] [--outdir X] [--only StepCount,HeartRate]`.
allowed-tools: Bash
argument-hint: [<path to export.zip> | --list | --outdir <dir> | --only <Type,Type>]
---

Run the apple-skill `health-export` parser on `$ARGUMENTS`.

Apple gates HealthKit — the only export is the manual iPhone tap that produces
`export.zip`. This tool is the Mac-side half: it parses `export.xml` into files.

Use Bash to execute (one call, then stop):

```
/Users/esaruoho/work/apple/bin/health-export $ARGUMENTS
```
