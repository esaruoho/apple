#!/usr/bin/env python3
"""
Build a signed "Turn into Voice" Finder Quick Action Shortcut.

After import:
  Shortcuts.app → "Turn into Voice" → ⓘ → Use as Quick Action → ✅ Finder
Then right-click any .txt / .md / .rtf in Finder → Quick Actions → Turn into Voice.

For each selected file, the Shortcut reads its text and submits it to the
voicebox-submit pipeline (Syncthing → Mac Mini → Voicebox → WAV back). A
notification confirms how many files were queued. Result WAVs land at
~/work/comms/queue/voicebox-results/<id>.wav once the worker finishes.

Output: shortcuts/finder/Turn into Voice.shortcut  (signed)
"""
import plistlib
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT_DIR = ROOT / "shortcuts/finder"
OUT_DIR.mkdir(parents=True, exist_ok=True)

NAME = "Turn into Voice"
SUBMIT_BIN = str(ROOT / "bin/voicebox-submit")

APPLESCRIPT = r'''on run {input, parameters}
	if input is missing value or (count of input) = 0 then return input
	set submitBin to "''' + SUBMIT_BIN + r'''"
	set submitted to 0
	set failed to {}
	repeat with f in input
		try
			set p to POSIX path of (f as alias)
			do shell script quoted form of submitBin & " " & quoted form of p
			set submitted to submitted + 1
		on error errMsg
			set end of failed to errMsg
		end try
	end repeat
	if (count of failed) = 0 then
		display notification "Queued " & submitted & " file" & (if submitted = 1 then "" else "s") & ". Watch voicebox-results for WAVs." with title "Turn into Voice" subtitle "Submitted to Mac Mini via Syncthing"
	else
		display notification (submitted as text) & " queued, " & (count of failed) & " failed" with title "Turn into Voice" subtitle (item 1 of failed)
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
        'WFWorkflowIconGlyphNumber': 61511,           # speaker / waveform glyph
        'WFWorkflowIconStartColor': 4282601983,       # blue
    },
    'WFWorkflowImportQuestions': [],
    # Accept text-bearing files from Finder Quick Actions.
    'WFWorkflowInputContentItemClasses': [
        'WFGenericFileContentItem',
        'WFStringContentItem',
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
print(f"  Search 'Turn into Voice' → ⓘ → Use as Quick Action → ✅ Finder")
print()
print("Then in Finder:")
print(f"  Right-click any .txt / .md / .rtf → Quick Actions → Turn into Voice")
print(f"  Results land at: ~/work/comms/queue/voicebox-results/<id>.wav")
