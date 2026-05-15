---
description: List all registered macOS Vocal Shortcuts (spoken phrase → Shortcut UUID). Reads ~/Library/Preferences/com.apple.Accessibility.plist. Usage `/vocal-shortcuts-list`.
allowed-tools: Bash
argument-hint: (no arguments)
---

Dump every Vocal Shortcut entry on this Mac: phrase, target Shortcut name, UUID.

Use Bash to execute (one call, then stop):

```
/Users/esaruoho/work/apple/bin/list-vocal-shortcuts.py
```

After the command completes, report the list verbatim.
