---
description: Build + open the "Delete Immediately" Finder Quick Action Shortcut. After import, enable it for Finder in Shortcuts.app. Then right-click → Quick Actions → Delete Immediately bypasses the Trash. Usage `/delete-now`.
allowed-tools: Bash
argument-hint: (no args)
---

Build the signed `.shortcut` and open it so Shortcuts.app imports it.

Use Bash (one call, then stop):

```
/Users/esaruoho/work/apple/bin/build-delete-now-shortcut.py && open '/Users/esaruoho/work/apple/shortcuts/finder/Delete Immediately.shortcut'
```

After import, tell the user (one line):
- In Shortcuts.app, open **Delete Immediately** → ⓘ → ✅ **Use as Quick Action → Finder**, then right-click any file/folder in Finder → **Quick Actions → Delete Immediately**.
