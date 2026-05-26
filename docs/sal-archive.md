---
layout: default
title: "Sal Archive Operations"
---

# Sal Archive Operations


[← Back to home](./)
Use the repo's archive tooling instead of ad hoc summaries:

- `python3 bin/sal-archive-status.py --write analysis/sal/current-status.md`
  Refreshes the live archive dashboard and remaining-work list.
- `python3 bin/sal-index-download-targets.py`
  Rebuilds the machine-readable download/media target index from the mirrored pages.
- `python3 bin/sal-recover-downloads.py --site macosxautomation.com --asset-type zip --strategy live-direct --mark-failures`
  Recovers missing bundles with live fetch first and Wayback fallback.

Rules:

- Do not claim a site is "done" unless the generated status says the missing queue is zero or the remaining gaps are explicitly documented.
- Keep `.failed` markers for dead URLs so the archive remains honest.
- Keep large recovered media local-only for later transcription rather than pushing them into git history.
