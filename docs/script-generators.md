---
layout: default
title: "Script generators — workflow-gen, shortcut-gen, batch-import"
---

# Script generators — workflow-gen, shortcut-gen, batch-import


[← Back to home](./)
Three Python tools in `bin/` that turn the curated recipe registry into runnable artifacts.

## `bin/workflow-gen.py`

- 186 curated workflow recipes across 16 apps.
- `--catalog` flag auto-regenerates [`wiki/compiled/scripts.md`](../compiled/scripts.md).
- Apps covered: Finder (28), Music (37), Mail (13), Safari (15), System Events (26), Calendar (9), Reminders (9), Notes (8), Photos (9), Shortcuts (4), Terminal (6), QuickTime (6), Messages (3), TextEdit (5), Contacts (4), HomePod (4).
- Teaching comments auto-detected for 15 AppleScript concepts (`tell`, `try`, `display`, `do shell script`, etc.).

## `bin/shortcut-gen.py`

- Generates signed `.shortcut` files with the native Run AppleScript action.
- **Action identifier:** `is.workflow.actions.runapplescript` (NOT `runscript` or `runshellscript`).
- **Parameter:** `Script` (raw AppleScript code, no `osascript` wrapper needed).
- `--phrases` flag shows Siri voice commands.
- `--setup` flag opens Shortcuts Advanced prefs (navigates to Advanced tab via UI scripting).
- **Prerequisite:** Shortcuts.app → Settings → Advanced → Allow Running Scripts (one-time).
- `shortcuts sign` has intermittent failures (~2–5 per run), retries fix them.
- `shortcuts/` directory is gitignored (binary signed files).

## `bin/batch-import.sh`

- Imports `.shortcut` files into Shortcuts.app via UI scripting.
- Creates "Apple Workflows" folder via AppleScript: `make new folder with properties {name:"Apple Workflows"}`.
- Moves shortcuts to folder: `set folder of shortcut "name" to folder "Apple Workflows"`.
- Import dialog: `open file.shortcut` then click `button 2 of scroll area 1 of group 1 of window 1`.
- Handles Replace dialog for duplicates.
- Shortcuts.app HAS a scripting dictionary: folders (create, list), shortcuts (name, folder, run).
- `shortcuts` CLI only supports: `run`, `list`, `view`, `sign` — NO import or create-folder.
