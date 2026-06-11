---
description: Read & control Finder ▸ Settings via `defaults` (no UI scripting). Show every toggle, flip booleans, set search scope, or apply Esa's preset. Apple-native. Usage `/finder-settings [show|set <name> on|off|search <scope>|apply|help]`.
allowed-tools: Bash
argument-hint: [show | set <name> on|off | search current|thismac|previous | apply | help]
---

Run the apple-skill `finder-settings` wrapper on `$ARGUMENTS`.

Use Bash to execute (one call, then stop):

```
/Users/esaruoho/work/apple/bin/finder-settings $ARGUMENTS
```
