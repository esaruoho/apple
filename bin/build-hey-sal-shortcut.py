#!/usr/bin/env python3
"""
Build "Hey Sal" — the Sal-Siri router Shortcut, no Apple Intelligence required.

Two actions in the .shortcut:
  1. Dictate Text  — pops up a microphone listener; captures what you say
  2. Run AppleScript — passes the dictated text to bin/sal-siri-match.py,
                        runs the matched DC-XXX handler

The match logic lives in bin/sal-siri-match.py (Python fuzzy-keyword matcher
against ~/Library/Application Support/Sal-Siri/intents.json). No Foundation
Models call. Works on any Mac that has Sal's libraries installed.

Output: shortcuts/sal-dictation/Hey Sal.shortcut (signed, importable)
"""
import plistlib
import subprocess
import sys
import uuid
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT_DIR = ROOT / "shortcuts/sal-dictation"
OUT_DIR.mkdir(parents=True, exist_ok=True)

NAME = "Hey Sal"
unsigned = OUT_DIR / f"{NAME}.unsigned.shortcut"
signed = OUT_DIR / f"{NAME}.shortcut"

# The AppleScript run by action 2. Receives dictated text via Shortcut input.
# Run AppleScript actions in Shortcuts get input as `on run {input, parameters}`
# where input is a list whose first item is the upstream value (the dictated text).
APPLESCRIPT_ROUTER = r'''on run {input, parameters}
	-- Debug log every invocation. Shows what Shortcuts is actually piping.
	set logPath to (POSIX path of (path to home folder)) & "Library/Logs/HeySal.log"
	set inputClass to "?"
	try
		set inputClass to (class of input) as text
	end try
	set inputDump to ""
	try
		set inputDump to (input as text)
	on error
		try
			set inputDump to "<list of " & (count of input) & ">"
		on error
			set inputDump to "<unprintable>"
		end try
	end try
	set paramsDump to ""
	try
		set paramsDump to (parameters as text)
	end try
	do shell script "/bin/echo " & quoted form of ("--- " & ((current date) as text) & " ---" & linefeed & "input class: " & inputClass & linefeed & "input dump:  " & inputDump & linefeed & "params dump: " & paramsDump) & " >> " & quoted form of logPath

	set theText to ""
	try
		if input is missing value then
			set theText to ""
		else if class of input is list then
			repeat with i in input
				try
					set theText to theText & " " & (i as text)
				end try
			end repeat
		else
			set theText to input as text
		end if
	end try
	set theText to my trim(theText)

	if theText is "" then
		say "I heard nothing"
		return "no input"
	end if

	set matchCmd to "/usr/bin/python3 " & quoted form of (POSIX path of (path to home folder)) & "work/apple/bin/sal-siri-match.py " & quoted form of theText
	set matchedScript to ""
	try
		set matchedScript to do shell script matchCmd
	on error errMsg number errNum
		if errNum is 1 then
			say "I did not understand. " & theText
			return "no match: " & theText
		end if
		say "Matcher error"
		return "matcher error: " & errMsg
	end try

	if matchedScript is "" then
		say "I did not understand. " & theText
		return "no match: " & theText
	end if

	try
		run script matchedScript
	on error errMsg
		say "Run failed. " & errMsg
		return "run failed: " & errMsg
	end try
	return "ok: " & theText
end run

on trim(s)
	set s to s as text
	repeat while s starts with " "
		if (length of s) is 1 then return ""
		set s to text 2 thru -1 of s
	end repeat
	repeat while s ends with " "
		if (length of s) is 1 then return ""
		set s to text 1 thru -2 of s
	end repeat
	return s
end trim'''

dictate_uuid = str(uuid.uuid4()).upper()
shell_uuid = str(uuid.uuid4()).upper()

# Single shell script that takes dictated text as $1, runs matcher, executes result
# via osascript. Logs to ~/Library/Logs/HeySal.log for debugging.
SHELL_SCRIPT = r'''#!/bin/zsh
LOG="$HOME/Library/Logs/HeySal.log"
STDIN_TEXT=$(cat)
ARGS_TEXT="$*"
TEXT="${STDIN_TEXT:-$ARGS_TEXT}"
{
  echo "--- $(date) ---"
  echo "argc: $#"
  echo "argv: '$ARGS_TEXT'"
  echo "stdin: '$STDIN_TEXT'"
  echo "env-shortcut: $(env | grep -i SHORTCUT)"
  echo "chosen: '$TEXT'"
} >> "$LOG"

if [ -z "$TEXT" ]; then
  /usr/bin/say "I heard nothing"
  exit 0
fi

MATCHED=$(/usr/bin/python3 "$HOME/work/apple/bin/sal-siri-match.py" "$TEXT" 2>>"$LOG")
RC=$?
echo "match rc: $RC" >> "$LOG"
echo "matched script:" >> "$LOG"
echo "$MATCHED" >> "$LOG"

if [ $RC -ne 0 ] || [ -z "$MATCHED" ]; then
  /usr/bin/say "I did not understand. $TEXT"
  exit 0
fi

# Run the matched AppleScript
/usr/bin/osascript -e "$MATCHED" 2>>"$LOG"
'''

plist = {
    'WFWorkflowActions': [
        # Action 1: Dictate Text — opens the round red record indicator immediately
        {
            'WFWorkflowActionIdentifier': 'is.workflow.actions.dictatetext',
            'WFWorkflowActionParameters': {
                'UUID': dictate_uuid,
                'WFDictateTextLanguage': 'en-US',
                'WFDictateTextStopListening': 'After Short Pause',
            },
        },
        # Action 2: Run Shell Script — try ALL plausible input plist keys at once.
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
                        'OutputName': 'Dictated Text',
                        'OutputUUID': dictate_uuid,
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
print(f"Open:  open '{signed}'")
