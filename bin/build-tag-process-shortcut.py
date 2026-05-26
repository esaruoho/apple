#!/usr/bin/env python3
"""
Build a signed "Tag: Process" Finder Quick Action Shortcut.

After import:
  Shortcuts.app → "Tag: Process" → ⓘ → Use as Quick Action → ✅ Finder
Then either:
  - right-click selection → Quick Actions → Tag: Process, or
  - View → Customize Toolbar… in any Finder window and drag the
    "Tag: Process" shortcut button into the toolbar for one-click tagging.

The Shortcut takes the selected Finder items and adds the tag "process"
to each, preserving any tags already on the file. Re-runnable; calling
it on a file that already has "process" is a no-op.

Re-run safely. Output goes to shortcuts/finder/Tag Process.shortcut.
"""
import plistlib
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT_DIR = ROOT / "shortcuts/finder"
OUT_DIR.mkdir(parents=True, exist_ok=True)

NAME = "Tag Process"
TAG_BIN = ROOT / "bin" / "tag"

APPLESCRIPT = f'''on run {{input, parameters}}
	if input is missing value or (count of input) = 0 then return input
	set tagBin to "{TAG_BIN.as_posix()}"
	set failed to {{}}
	repeat with f in input
		try
			set p to POSIX path of (f as alias)
			do shell script tagBin & " add process " & quoted form of p
		on error errMsg
			set end of failed to (p & " — " & errMsg)
		end try
	end repeat
	if (count of failed) > 0 then
		set summary to ""
		repeat with line in failed
			set summary to summary & (line as text) & linefeed
		end repeat
		display alert "Tag: Process — some items failed" message summary as warning
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
        'WFWorkflowIconGlyphNumber': 61722,           # tag glyph
        'WFWorkflowIconStartColor': 4292311040,       # red
    },
    'WFWorkflowImportQuestions': [],
    'WFWorkflowInputContentItemClasses': [
        'WFGenericFileContentItem',
        'WFFolderContentItem',
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
print()
print("Then in Shortcuts.app:")
print(f"  Search 'Tag: Process' → ⓘ → Use as Quick Action → ✅ Finder")
print()
print("Then in Finder:")
print(f"  View → Customize Toolbar… → drag 'Tag: Process' into the toolbar")
print(f"  (or right-click selection → Quick Actions → Tag: Process)")
