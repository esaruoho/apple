#!/usr/bin/env python3
"""
Build "Hey Sal Type" — sibling Shortcut to "Hey Sal" but typed instead of
spoken. Pin it to the Shortcuts.app menu bar alongside "Hey Sal" and you
get both Voice and Type under one ⚡ icon.

Two actions in the .shortcut:
  1. Ask for Input  — pops a text dialog, captures what you typed
  2. Run Shell Script — passes the typed text to ~/work/apple/bin/hey-sal,
                        which knows the 337 Paketti voice verbs plus the
                        Sal-Siri intents and routes to the right wrapper.

Output: shortcuts/sal-dictation/Hey Sal Type.shortcut (signed, importable)
Open the file once to import into Shortcuts.app, then in Shortcuts.app
right-click → Pin in Menu Bar.
"""
import plistlib
import subprocess
import sys
import uuid
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT_DIR = ROOT / "shortcuts/sal-dictation"
OUT_DIR.mkdir(parents=True, exist_ok=True)

NAME = "Hey Sal Type"
unsigned = OUT_DIR / f"{NAME}.unsigned.shortcut"
signed = OUT_DIR / f"{NAME}.shortcut"

ask_uuid = str(uuid.uuid4()).upper()
shell_uuid = str(uuid.uuid4()).upper()

SHELL_SCRIPT = r'''#!/bin/zsh
LOG="$HOME/Library/Logs/HeySal.log"
STDIN_TEXT=$(cat)
ARGS_TEXT="$*"
TEXT="${STDIN_TEXT:-$ARGS_TEXT}"
{
  echo "--- $(date) (typed via menubar) ---"
  echo "input: '$TEXT'"
} >> "$LOG"

if [ -z "$TEXT" ]; then
  exit 0
fi

# Route via the unified hey-sal Python router. It knows the 337 Paketti
# verbs (built by build-paketti-verbs.py) plus the original Sal intents.
RESULT=$("$HOME/work/apple/bin/hey-sal" "$TEXT" 2>&1)
RC=$?
echo "rc: $RC" >> "$LOG"
echo "result:" >> "$LOG"
echo "$RESULT" >> "$LOG"
echo "$RESULT"
'''

plist = {
    'WFWorkflowActions': [
        # Action 1: Ask for Input — pops a text dialog
        {
            'WFWorkflowActionIdentifier': 'is.workflow.actions.ask',
            'WFWorkflowActionParameters': {
                'UUID': ask_uuid,
                'WFAskActionPrompt': 'Hey Sal:',
                'WFInputType': 'Text',
                'WFAskActionDefaultAnswer': '',
            },
        },
        # Action 2: Run Shell Script — pipe the typed text to hey-sal
        {
            'WFWorkflowActionIdentifier': 'is.workflow.actions.runshellscript',
            'WFWorkflowActionParameters': {
                'UUID': shell_uuid,
                'Script': SHELL_SCRIPT,
                'Shell': '/bin/zsh',
                'Input': 'Connect Input',
                'InputMode': 'to stdin',
                'WFShellActionShell': '/bin/zsh',
                'WFShellActionInputMode': 'to stdin',
                'WFInput': {
                    'Value': {
                        'OutputName': 'Provided Input',
                        'OutputUUID': ask_uuid,
                        'Type': 'ActionOutput',
                    },
                    'WFSerializationType': 'WFTextTokenAttachment',
                },
            },
        },
    ],
    'WFWorkflowClientVersion': '2612.0.4',
    'WFWorkflowHasOutputFallback': False,
    'WFWorkflowHasShortcutInputVariables': False,
    # Different glyph + colour from the voice variant so they're easy to
    # tell apart in the Shortcuts menu bar.
    'WFWorkflowIcon': {'WFWorkflowIconGlyphNumber': 61492, 'WFWorkflowIconStartColor': 2071128575},
    'WFWorkflowImportQuestions': [],
    'WFWorkflowInputContentItemClasses': ['WFStringContentItem'],
    'WFWorkflowMinimumClientVersion': 900,
    'WFWorkflowMinimumClientVersionString': '900',
    'WFWorkflowOutputContentItemClasses': [],
    'WFWorkflowTypes': [
        # Surface in the Shortcuts.app menu bar pin list.
        'MenuBar',
    ],
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
print(f"Import: open '{signed}'")
