---
description: Safely inspect, dry-run, and unmount/purge iOS Simulator runtime DMGs, dyld shared caches, and unavailable device stubs via xcrun simctl. Usage `/sim-purge [list | dry-run [id|all] | delete <id|all> | prune | cache-remove [id]]`.
allowed-tools: Bash
argument-hint: [list | dry-run [id|all] | delete <id|all> | prune | cache-remove [id]]
---

Run the apple-skill `sim-purge` wrapper on `$ARGUMENTS`.

Use Bash to execute (one call, then stop):

```
/Users/esaruoho/work/apple/bin/sim-purge $ARGUMENTS
```
