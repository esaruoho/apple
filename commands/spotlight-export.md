---
description: Compile workflow scripts to Spotlight-reachable .app bundles in ~/Applications/Apple-Workflows/. Usage `/spotlight-export` (all) or `/spotlight-export finder music` (subset).
allowed-tools: Bash
argument-hint: [app-names...] [--dry-run] [--clean] [--list]
---

Build Spotlight-indexed .app launchers for every workflow script. One Cmd-Space away.

Use Bash to execute (one call, then stop):

```
/Users/esaruoho/work/apple/bin/spotlight-export.sh $ARGUMENTS
```

After the command completes, report the count of apps written and the output directory. Nothing else.
