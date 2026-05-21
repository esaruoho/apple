#!/usr/bin/env python3
"""
Build a signed "Delete Immediately" Finder Quick Action Shortcut.

After import:
  Shortcuts.app → "Delete Immediately" → ⓘ → Use as Quick Action → ✅ Finder
Then right-click any file/folder in Finder → Quick Actions → Delete Immediately.

The Shortcut takes the selected files, asks once for confirmation, then
unlinks them with rm -rf. Bypasses the Trash — same semantics as ⌥⌘⌫.

Re-run safely. Output goes to shortcuts/finder/Delete Immediately.shortcut.
"""
import plistlib
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT_DIR = ROOT / "shortcuts/finder"
OUT_DIR.mkdir(parents=True, exist_ok=True)

NAME = "Delete Immediately"

# Single AppleScript action: receives Shortcut input (the selected Finder
# items as a list of files), counts them, asks once, then rm -rf each.
APPLESCRIPT = r'''on run {input, parameters}
	if input is missing value or (count of input) = 0 then return input
	set n to count of input
	set msg to "Permanently delete " & n & " item" & (if n = 1 then "" else "s") & "?\n\nThis bypasses the Trash."
	display alert "Delete Immediately" message msg buttons {"Cancel", "Delete"} default button "Cancel" cancel button "Cancel" as critical
	repeat with f in input
		try
			set p to POSIX path of (f as alias)
			do shell script "/bin/rm -rf -- " & quoted form of p
		on error errMsg
			-- skip and continue
		end try
	end repeat
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
        'WFWorkflowIconGlyphNumber': 61477,           # trash glyph
        'WFWorkflowIconStartColor': 4292311040,       # red
    },
    'WFWorkflowImportQuestions': [],
    # Accept files + folders from Finder Quick Actions.
    'WFWorkflowInputContentItemClasses': [
        'WFGenericFileContentItem',
        'WFFolderContentItem',
    ],
    'WFWorkflowMinimumClientVersion': 900,
    'WFWorkflowMinimumClientVersionString': '900',
    'WFWorkflowOutputContentItemClasses': [],
    # Surface as a Finder Quick Action. The user still confirms the checkbox
    # in Shortcuts.app once after import — Apple gates this behind UI consent.
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
print(f"  Search 'Delete Immediately' → ⓘ → Use as Quick Action → ✅ Finder")
print()
print("Then in Finder:")
print(f"  Right-click any file/folder → Quick Actions → Delete Immediately")
