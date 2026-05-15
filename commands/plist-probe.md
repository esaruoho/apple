---
description: Scan every Apple-app plist for extractable user data (1,934 plists, 518 apps). Apple-native plistlib only. Usage `/plist-probe` or `/plist-probe --md` or `/plist-probe --interesting-only`.
allowed-tools: Bash
argument-hint: [--md] [--json] [--interesting-only]
---

Survey every Apple-app plist on disk and report which apps actually persist user data worth exporting.

Use Bash to execute (one call, then stop):

```
/Users/esaruoho/work/apple/bin/app-plist-probe.py $ARGUMENTS
```

After the command completes, report the top mineable apps verbatim. No editorializing.
