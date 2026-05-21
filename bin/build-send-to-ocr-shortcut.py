#!/usr/bin/env python3
"""
Build a signed "Send to OCR" Finder Quick Action Shortcut.

After import:
  Shortcuts.app → "Send to OCR" → ⓘ → Use as Quick Action → ✅ Finder
Then right-click any .pdf in Finder → Quick Actions → Send to OCR.

For each selected PDF, the Shortcut stamps `needs-ocr:red` on it and fires
the tag-watcher, which drops the file into ~/work/comms/queue/ocr-inbox/
(Syncthing → Mac Mini → OCR worker → results back into ocr-results/).
A notification confirms how many files were queued.

Output: shortcuts/finder/Send to OCR.shortcut  (signed)
"""
import plistlib
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT_DIR = ROOT / "shortcuts/finder"
OUT_DIR.mkdir(parents=True, exist_ok=True)

NAME = "Send to OCR"
TAG_BIN = str(ROOT / "bin/tag")
WATCHER_BIN = str(ROOT / "bin/tag-watcher")

APPLESCRIPT = r'''on run {input, parameters}
	if input is missing value or (count of input) = 0 then return input
	set tagBin to "''' + TAG_BIN + r'''"
	set watcherBin to "''' + WATCHER_BIN + r'''"
	set submitted to 0
	set failed to {}
	repeat with f in input
		try
			set p to POSIX path of (f as alias)
			do shell script quoted form of tagBin & " add needs-ocr:red " & quoted form of p
			set submitted to submitted + 1
		on error errMsg
			set end of failed to errMsg
		end try
	end repeat
	-- Fire the watcher once so files go out immediately, no 60s wait.
	try
		do shell script quoted form of watcherBin & " --once needs-ocr"
	end try
	if (count of failed) = 0 then
		display notification "Tagged " & submitted & " PDF" & (if submitted = 1 then "" else "s") & " → Mac Mini via Syncthing." with title "Send to OCR" subtitle "Result-handler will swap them to ocr-complete when worker returns"
	else
		display notification (submitted as text) & " tagged, " & (count of failed) & " failed" with title "Send to OCR" subtitle (item 1 of failed)
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
        'WFWorkflowIconGlyphNumber': 59507,         # gear / processing glyph
        'WFWorkflowIconStartColor': 4282601983,     # blue
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
print()
print("Then in Shortcuts.app:")
print(f"  Search 'Send to OCR' → ⓘ → Use as Quick Action → ✅ Finder")
print()
print("Then in Finder:")
print(f"  Right-click any .pdf → Quick Actions → Send to OCR")
print(f"  Watch:  tail -f ~/work/comms/queue/tag-watcher.log")
