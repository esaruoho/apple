---
description: Which Safari tab is eating the power? Rank Safari processes, map front tabs to PIDs, select or close the worst offender.
allowed-tools: Bash
argument-hint: procs | tabs | worst | close-worst [--sample N] [--json]
---

Run the apple-skill `safari-hogs` tool on `$ARGUMENTS` (default `tabs`).

```
/Users/esaruoho/work/apple/bin/safari-hogs ${ARGUMENTS:-tabs}
```

- `procs`: rank Safari Web Content/GPU/Networking processes by CPU, energy and RAM. No side effects.
- `tabs`: JS-probe each window's FRONT tab (media playing, DOM nodes, iframes) and map it to its PID.
- `worst`: bring the worst front tab forward (select it).
- `close-worst`: select it, then ask y/N before closing. Do not answer the y/N for the user.

If a hot PID hosts only background tabs, report it as unmapped; don't JS-probe background tabs (that wakes them).
Wiki: `wiki/concepts/safari-tab-power.md`.
