#!/usr/bin/env python3
"""
Build a signed "Pin in AppleToolbox" Finder Quick Action Shortcut.

After import:
  Shortcuts.app → "Pin in AppleToolbox" → ⓘ → Use as Quick Action → ✅ Finder
  Also ✅ "Show in Finder toolbar" so it surfaces as a toolbar button you can
  drop files onto.

What it does: for each selected file/folder in Finder, runs
  open -a /Applications/Apple-Workflows/AppleToolbox.app <path>
which dispatches an Apple Event to the already-running AppleToolbox.app —
its NSApplicationDelegate.application(_:open:) handler stores the path under
UserDefaults["PinnedFile"] and refreshes the menu so a "📌 <filename>" row
appears at the top of the 🧰 dropdown.

This is the lightweight, in-process Apple-native replacement for a drop-target
wrapper .app — no cold-start, no Dock-icon flash.

Output: shortcuts/finder/Pin in AppleToolbox.shortcut  (signed)
"""
import plistlib
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT_DIR = ROOT / "shortcuts/finder"
OUT_DIR.mkdir(parents=True, exist_ok=True)

NAME = "Pin in AppleToolbox"
TARGET_APP = "/Applications/Apple-Workflows/AppleToolbox.app"

APPLESCRIPT = r'''on run {input, parameters}
	if input is missing value or (count of input) = 0 then return input
	set targetApp to "''' + TARGET_APP + r'''"
	set lastPath to ""
	repeat with f in input
		try
			set p to POSIX path of (f as alias)
			set lastPath to p
			do shell script "/usr/bin/open -a " & quoted form of targetApp & " " & quoted form of p
		end try
	end repeat
	if lastPath is not "" then
		set nameOnly to do shell script "basename " & quoted form of lastPath
		display notification ("📌 " & nameOnly) with title "AppleToolbox" subtitle "Pinned — click 🧰 menu to see it"
	end if
	return input
end run'''

plist = {
    'WFWorkflowActions': [
        {
            'WFWorkflowActionIdentifier': 'is.workflow.actions.runapplescript',
            'WFWorkflowActionParameters': {'Script': APPLESCRIPT},
        }
    ],
    'WFWorkflowClientVersion': '2612.0.4',
    'WFWorkflowHasOutputFallback': False,
    'WFWorkflowHasShortcutInputVariables': True,
    'WFWorkflowIcon': {
        'WFWorkflowIconGlyphNumber': 61440,         # pin glyph
        'WFWorkflowIconStartColor': 4292311551,     # orange
    },
    'WFWorkflowImportQuestions': [],
    'WFWorkflowInputContentItemClasses': [
        'WFGenericFileContentItem',
    ],
    'WFWorkflowMinimumClientVersion': 900,
    'WFWorkflowMinimumClientVersionString': '900',
    'WFWorkflowOutputContentItemClasses': [],
    'WFQuickActionSurfaces': ['Finder'],
    'WFWorkflowTypes': ['NCWidget', 'WatchKit'],
}

unsigned = OUT_DIR / f"{NAME}.unsigned.shortcut"
signed = OUT_DIR / f"{NAME}.shortcut"

with unsigned.open('wb') as f:
    plistlib.dump(plist, f, fmt=plistlib.FMT_BINARY)

result = subprocess.run(
    ['shortcuts', 'sign', '--mode', 'anyone',
     '--input', str(unsigned), '--output', str(signed)],
    capture_output=True, text=True,
)
if result.returncode != 0:
    sys.exit(f"sign failed: {result.stderr}")
unsigned.unlink()

print(f"Built: {signed}")
print()
print("Install:")
print(f"  open '{signed}'")
