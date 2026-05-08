#!/usr/bin/env python3
"""
Build the master "Sal Vacation Demo" Shortcut — runs Sal's WWDC 717 demo
arc end-to-end with `say` narration between steps.

The orchestrator is a single Run AppleScript that calls each sub-Shortcut
via `tell application "Shortcuts" to run shortcut "..."`, narrates via `say`,
and pauses where Sal would have paused.

Output: shortcuts/sal-dictation/Sal Vacation Demo.shortcut (signed).
"""
import plistlib
import subprocess
import uuid
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT_DIR = ROOT / "shortcuts/sal-dictation"
OUT_DIR.mkdir(parents=True, exist_ok=True)

# Each step: (narration, shortcut_name_to_run, post_delay_seconds)
# narration "" = silent step; shortcut_name "" = pause-only narration.
ARC = [
    ("Welcome. This is Sal Soghoian's W W D C 2016 session 717 demo, recreated. Make sure Photos has some pictures. Starting in five seconds.", "", 5),

    # Stage 1: Photos titling — start in Photos
    ("Stage one. Switching to Photos.", "Switch To Photos", 1.5),
    ("", "Select All Photos", 1),
    # The assistive title-loop is custom; skipping for the bare demo.
    # Audience can dictate titles manually — show that's possible.

    # Stage 2: Build presentation
    ("Stage two. Making a new presentation.", "Make A New Presentation", 2.5),
    ("", "Add A Blank Slide", 1),

    # Stage 5: Visual polish
    ("Stage five. Applying a magic move transition.", "Apply Magic Move", 1.5),
    ("And a dissolve.", "Apply Dissolve", 1.5),

    # Stage 8: QR + duplicate
    ("Stage eight. Duplicating the current slide.", "Duplicate Current Slide", 1.5),

    # Final
    ("Demo complete. Apple killed this in 2016. It runs on your 2026 Mac.", "", 0),
]

# Build the AppleScript
lines = ['on run', '\tset narrationDelay to 0.4']
for i, (narration, shortcut_name, delay) in enumerate(ARC):
    if narration:
        # Escape double quotes in narration
        n = narration.replace('"', '\\"')
        lines.append(f'\tsay "{n}"')
    if shortcut_name:
        sn = shortcut_name.replace('"', '\\"')
        # Use the shortcuts CLI (reliable, UI-aware) instead of "Shortcuts Events"
        # (which is headless and can't fire UI-bearing actions).
        lines.append(f'\ttry')
        lines.append(f'\t\tdo shell script "/usr/bin/shortcuts run " & quoted form of "{sn}"')
        lines.append(f'\ton error errMsg')
        lines.append(f'\t\tsay "Step {i + 1} failed: {sn}."')
        lines.append(f'\tend try')
    if delay > 0:
        lines.append(f'\tdelay {delay}')
lines.append('end run')
applescript = '\n'.join(lines)

NAME = "Sal Vacation Demo"
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
