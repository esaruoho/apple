---
description: Build + open the "Tag: Process" Finder Quick Action Shortcut. After import, enable for Finder and drag to the toolbar. One click tags all selected files with `process`. Usage `/tag-process`.
allowed-tools: Bash
argument-hint: (no args)
---

Build the signed `.shortcut` and open it so Shortcuts.app imports it.

Use Bash (one call, then stop):

```
/Users/esaruoho/work/apple/bin/build-tag-process-shortcut.py && open '/Users/esaruoho/work/apple/shortcuts/finder/Tag Process.shortcut'
```

After import, tell the user (one line):
- In Shortcuts.app, open **Tag: Process** → ⓘ → ✅ **Use as Quick Action → Finder**. Then in any Finder window: **View → Customize Toolbar…** and drag **Tag: Process** into the toolbar. Select files → click the toolbar button → all selected files get the `process` tag in one shot.
