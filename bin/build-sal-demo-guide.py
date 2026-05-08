#!/usr/bin/env python3
"""
Build "Sal Demo Guide" — a Shortcut that walks the user through speaking
Sal's WWDC 717 demo via Hey Sal, one command at a time.

Each step shows a display dialog: "Step N — Say 'Hey Sal' then '<command>'".
The user speaks the command via Hey Sal (which is a separate Vocal Shortcut).
After the action happens on screen, the user clicks Continue and the Guide
shows the next step.

This makes Hey Sal the actual driver of the demo (not a backstage shell call).
"""
import plistlib
import subprocess
import uuid
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT_DIR = ROOT / "shortcuts/sal-dictation"
OUT_DIR.mkdir(parents=True, exist_ok=True)

# (label, what to say, what should happen)
# Only commands that actually work today via user Shortcuts.
STEPS = [
    ("Stage 1 — Open Photos", "Switch to Photos", "Photos.app comes to the foreground."),
    ("Stage 1 — Select all", "Select all photos", "All photos in the current view are selected (Cmd-A)."),
    ("Stage 2 — New presentation", "Make a new presentation", "Keynote opens with a blank new presentation."),
    ("Stage 2 — Add a slide", "Add a blank slide", "A new blank slide appears in the front Keynote document."),
    ("Stage 5 — Magic move", "Apply magic move", "Current slide gets a Magic Move transition."),
    ("Stage 5 — Dissolve", "Apply dissolve", "Current slide gets a Dissolve transition."),
    ("Stage 8 — Duplicate", "Duplicate current slide", "Current slide is duplicated in the front document."),
    ("Bonus — QR code", "QR this", "Whatever's on your clipboard becomes a QR code on the front Keynote slide. (Copy a URL first, then say it.)"),
    ("Stage 7 — Save", "Save", "Front document saves."),
]

# Build the AppleScript with one display dialog per step
lines = ['on run']
lines.append('\tdisplay dialog "Sal Demo Guide" & linefeed & linefeed & "This walks you through Sal Soghoian\'s WWDC 2016 session 717 demo using Hey Sal." & linefeed & linefeed & "For each step, say \\"Hey Sal\\" then the command shown. Watch the action happen. Click Continue when ready for the next step." with title "Sal Demo Guide" buttons {"Cancel", "Start"} default button "Start"')
lines.append('\tif button returned of result is "Cancel" then return')
lines.append('')

for i, (label, command, expected) in enumerate(STEPS, start=1):
    cmd_esc = command.replace('"', '\\"')
    label_esc = label.replace('"', '\\"')
    expected_esc = expected.replace('"', '\\"')
    lines.append(f'\tdisplay dialog "Step {i} of {len(STEPS)} — {label_esc}" & linefeed & linefeed & "Say:  Hey Sal" & linefeed & "Then: {cmd_esc}" & linefeed & linefeed & "Expected: {expected_esc}" with title "Step {i} of {len(STEPS)}" buttons {{"Cancel", "Continue"}} default button "Continue"')
    lines.append(f'\tif button returned of result is "Cancel" then return')
    lines.append('')

lines.append('\tdisplay dialog "Demo complete." & linefeed & linefeed & "Apple killed this in November 2016. It runs on your 2026 Mac via Hey Sal — one Vocal Shortcut, voice-driving the same AppleScript substrate Sal designed." with title "Done" buttons {"Done"} default button "Done"')
lines.append('end run')
applescript = '\n'.join(lines)

NAME = "Sal Demo Guide"
unsigned = OUT_DIR / f"{NAME}.unsigned.shortcut"
signed = OUT_DIR / f"{NAME}.shortcut"

plist = {
    'WFWorkflowActions': [{
        'WFWorkflowActionIdentifier': 'is.workflow.actions.runapplescript',
        'WFWorkflowActionParameters': {
            'UUID': str(uuid.uuid4()).upper(),
            'Script': applescript,
        },
    }],
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
r = subprocess.run(['shortcuts','sign','--mode','anyone','--input',str(unsigned),'--output',str(signed)], capture_output=True, text=True)
unsigned.unlink(missing_ok=True)
if r.returncode == 0:
    print(f"Built: {signed}")
    print(f"Open:  open '{signed}'")
else:
    print(f"sign failed: {r.stderr}")
