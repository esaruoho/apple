---
description: Dock manager — list/add/remove items in macOS Dock (Apple-native, edits com.apple.dock.plist via plistlib). Usage `/dock <subcommand> [args]`.
allowed-tools: Bash
argument-hint: list | add <path> | add-spacer | remove <path|label> | clear-others
---

Run the apple-skill `dock` wrapper on `$ARGUMENTS`.

Use Bash to execute (one call, then stop):

```
/Users/esaruoho/work/apple/bin/dock $ARGUMENTS
```

Subcommands:
- `list` — show every Dock item (apps + folders/files)
- `add <path>` — add a folder, .savedSearch, file, or .app to the Dock
- `add-spacer` — add a blank spacer tile
- `remove <path|label>` — remove by full path or by displayed label
- `clear-others` — remove every persistent-others entry (right side)

Apple-native: plistlib only. After every write the script killalls cfprefsd and Dock so the change appears immediately.

After the command completes, report only the lines it printed.
