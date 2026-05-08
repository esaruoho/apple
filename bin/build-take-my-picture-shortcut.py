#!/usr/bin/env python3
"""
Build a single working .shortcut file: "Take My Picture"

Uses the same plist+sign technique as bin/shortcut-gen.py. Output:
  shortcuts/sal-dictation/Take My Picture.shortcut  (signed, importable)

Double-click the output file → Shortcuts.app imports it → press ▶ to test
→ bind "Take My Picture" as a Vocal Shortcut.
"""
import plistlib
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT_DIR = ROOT / "shortcuts/sal-dictation"
OUT_DIR.mkdir(parents=True, exist_ok=True)

NAME = "Take My Picture"
APPLESCRIPT = '''-- Native webcam capture via AVFoundation. Zero third-party deps — uses Apple's
-- own swiftc compiler (ships with macOS) to compile bin/sal-take-photo.swift
-- to a binary on first run, then invokes it. Replaces Sal's 2016 PictureTaker
-- Helper.app which on Sequoia opens the broken avatar picker.
on run
	set repoRoot to (POSIX path of (path to home folder)) & "work/apple"
	set swiftSrc to repoRoot & "/bin/sal-take-photo.swift"
	set swiftBin to repoRoot & "/bin/sal-take-photo"
	set picPath to (POSIX path of (path to home folder)) & "Pictures/sal-snap-" & (do shell script "date +%Y%m%d-%H%M%S") & ".jpg"
	-- Self-bootstrap: compile the Swift source to a binary if missing or stale.
	do shell script "if [ ! -x " & quoted form of swiftBin & " ] || [ " & quoted form of swiftSrc & " -nt " & quoted form of swiftBin & " ]; then /usr/bin/swiftc -O -o " & quoted form of swiftBin & " " & quoted form of swiftSrc & "; fi"
	do shell script quoted form of swiftBin & " " & quoted form of picPath
	tell application "Finder"
		activate
		reveal POSIX file picPath
	end tell
	return picPath
end run'''

unsigned = OUT_DIR / f"{NAME}.unsigned.shortcut"
signed = OUT_DIR / f"{NAME}.shortcut"

plist = {
    'WFWorkflowActions': [
        {
            'WFWorkflowActionIdentifier': 'is.workflow.actions.runapplescript',
            'WFWorkflowActionParameters': {'Script': APPLESCRIPT},
        }
    ],
    'WFWorkflowClientVersion': '2612.0.4',
    'WFWorkflowHasOutputFallback': False,
    'WFWorkflowHasShortcutInputVariables': False,
    'WFWorkflowIcon': {'WFWorkflowIconGlyphNumber': 59511, 'WFWorkflowIconStartColor': 4282601983},
    'WFWorkflowImportQuestions': [],
    'WFWorkflowInputContentItemClasses': ['WFStringContentItem'],
    'WFWorkflowMinimumClientVersion': 900,
    'WFWorkflowMinimumClientVersionString': '900',
    'WFWorkflowOutputContentItemClasses': [],
    'WFWorkflowTypes': [],
}

with open(unsigned, 'wb') as f:
    plistlib.dump(plist, f, fmt=plistlib.FMT_BINARY)

result = subprocess.run(
    ['shortcuts', 'sign', '--mode', 'anyone', '--input', str(unsigned), '--output', str(signed)],
    capture_output=True, text=True
)
if result.returncode != 0:
    print(f"sign failed: {result.stderr}", file=sys.stderr)
    sys.exit(1)
unsigned.unlink()
print(f"Built: {signed}")
print(f"Open: open '{signed}'")
