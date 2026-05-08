#!/usr/bin/env python3
"""
Build native-AppleScript Shortcuts for the WWDC 717 demo command set, bypassing
Sal's broken-on-Sequoia .scptd libraries. Each Shortcut is a single Run AppleScript
action with simple direct-app AppleScript — no DC-XXX library dependency, no
hardcoded bundle IDs.

The user's existing matcher already prefers user Shortcuts over Sal's catalog
(USER_BOOST=1.5), so once these are imported, "Hey Sal" → "make a new presentation"
routes to the user Shortcut instead of Sal's broken library.

Output: shortcuts/sal-dictation/<Name>.shortcut (signed, importable)
"""
import plistlib
import subprocess
import sys
import uuid
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT_DIR = ROOT / "shortcuts/sal-dictation"
OUT_DIR.mkdir(parents=True, exist_ok=True)

# Each entry: shortcut name, AppleScript body. Native — no Sal libraries.
DEMOS = [
    ("Make A New Presentation", '''tell application "Keynote"
\tactivate
\tmake new document
end tell'''),
    ("Switch To Photos", '''tell application "Photos" to activate'''),
    ("Select All Photos", '''tell application "Photos" to activate
delay 0.5
tell application "System Events" to keystroke "a" using command down'''),
    ("Switch To Keynote", '''tell application "Keynote" to activate'''),
    ("Switch To Maps", '''tell application "Maps" to activate'''),
    ("Switch To Numbers", '''tell application "Numbers" to activate'''),
    ("Switch To Pages", '''tell application "Pages" to activate'''),
    ("Open The Documents Folder", '''tell application "Finder"
\tactivate
\topen folder "Documents" of home
end tell'''),
    ("Open The Pictures Folder", '''tell application "Finder"
\tactivate
\topen folder "Pictures" of home
end tell'''),
    ("Open The Downloads Folder", '''tell application "Finder"
\tactivate
\topen folder "Downloads" of home
end tell'''),
    ("Close All Finder Windows", '''tell application "Finder"
\tclose every window
end tell'''),
    ("Hide Other Applications", '''tell application "System Events"
\tset visible of every process whose frontmost is false to false
end tell'''),
    ("Display Wifi Network Name", '''set ssid to do shell script "/usr/sbin/networksetup -getairportnetwork en0 | sed 's/Current Wi-Fi Network: //'"
display dialog "Wi-Fi: " & ssid with title "Network" buttons {"OK"} default button "OK"'''),
    ("Display Computer Name", '''set cname to do shell script "scutil --get ComputerName"
display dialog "Computer: " & cname with title "Hostname" buttons {"OK"} default button "OK"'''),
    ("New Mail Message", '''tell application "Mail"
\tactivate
\tset newMsg to make new outgoing message
\ttell newMsg to set visible to true
end tell'''),
    ("Add A Blank Slide", '''tell application "Keynote"
\tactivate
\ttell front document to make new slide
end tell'''),
    ("Go To Last Slide", '''tell application "Keynote"
\tactivate
\ttell front document to set current slide to last slide
end tell'''),
    ("Play Presentation", '''tell application "Keynote"
\tactivate
\ttell front document to start
end tell'''),
    ("Stop Presentation", '''tell application "Keynote"
\tactivate
\ttell front document to stop
end tell'''),
    ("Close Without Saving", '''tell application (path to frontmost application as text)
\ttry
\t\tclose front window saving no
\tend try
end tell'''),
    ("Insert Clipboard To Slide Title", '''set theText to (the clipboard as text)
tell application "Keynote"
\tactivate
\ttell front document
\t\ttell current slide
\t\t\tset object text of default title item to theText
\t\tend tell
\tend tell
end tell'''),
    ("Insert Clipboard To Slide Body", '''set theText to (the clipboard as text)
tell application "Keynote"
\tactivate
\ttell front document
\t\ttell current slide
\t\t\tset object text of default body item to theText
\t\tend tell
\tend tell
end tell'''),
    ("Next Slide", '''tell application "Keynote"
\tactivate
\ttell front document
\t\tset s to slide number of current slide
\t\tif s < (count of slides) then set current slide to slide (s + 1)
\tend tell
end tell'''),
    ("Previous Slide", '''tell application "Keynote"
\tactivate
\ttell front document
\t\tset s to slide number of current slide
\t\tif s > 1 then set current slide to slide (s - 1)
\tend tell
end tell'''),
    ("Go To First Slide", '''tell application "Keynote"
\tactivate
\ttell front document to set current slide to slide 1
end tell'''),
    ("Apply Magic Move", '''tell application "Keynote"
\ttell front document
\t\ttell current slide
\t\t\tset transition properties to {automatic transition:false, transition effect:magic move}
\t\tend tell
\tend tell
end tell'''),
    ("Apply Dissolve", '''tell application "Keynote"
\ttell front document
\t\ttell current slide
\t\t\tset transition properties to {automatic transition:false, transition effect:dissolve}
\t\tend tell
\tend tell
end tell'''),
    ("No Transition", '''tell application "Keynote"
\ttell front document
\t\ttell current slide
\t\t\tset transition properties to {automatic transition:false, transition effect:no transition}
\t\tend tell
\tend tell
end tell'''),
    ("Save Front Document", '''tell application (path to frontmost application as text)
\tsave front document
end tell'''),
    ("Duplicate Current Slide", '''tell application "Keynote"
\ttell front document
\t\tset s to current slide
\t\tduplicate s
\tend tell
end tell'''),
    ("Delete Current Slide", '''tell application "Keynote"
\ttell front document
\t\tdelete current slide
\tend tell
end tell'''),
    ("QR This", '''-- Generate a QR code from clipboard text and insert it into the front
-- Keynote slide. Native: Core Image CIQRCodeGenerator via bin/sal-qr.
on run
\tset repoRoot to (POSIX path of (path to home folder)) & "work/apple"
\tset swiftSrc to repoRoot & "/bin/sal-qr.swift"
\tset swiftBin to repoRoot & "/bin/sal-qr"
\t-- Self-bootstrap compile
\tdo shell script "if [ ! -x " & quoted form of swiftBin & " ] || [ " & quoted form of swiftSrc & " -nt " & quoted form of swiftBin & " ]; then /usr/bin/swiftc -O -o " & quoted form of swiftBin & " " & quoted form of swiftSrc & "; fi"
\tset theText to (the clipboard as text)
\tif theText is "" then
\t\tdisplay dialog "Clipboard is empty. Copy a URL or text first, then say QR This." with title "QR This" buttons {"OK"} default button "OK"
\t\treturn
\tend if
\tset picPath to (POSIX path of (path to home folder)) & "Pictures/sal-qr-" & (do shell script "date +%Y%m%d-%H%M%S") & ".png"
\tdo shell script quoted form of swiftBin & " " & quoted form of theText & " " & quoted form of picPath
\ttell application "Keynote"
\t\tactivate
\t\ttry
\t\t\ttell front document
\t\t\t\ttell current slide
\t\t\t\t\tmake new image with properties {file:(POSIX file picPath)}
\t\t\t\tend tell
\t\t\tend tell
\t\ton error
\t\t\t-- No open Keynote document; just reveal the PNG in Finder so user has it
\t\t\ttell application "Finder" to reveal POSIX file picPath
\t\tend try
\tend tell
end run'''),
    ("QR My Clipboard", '''-- Generate a QR code from clipboard, save to ~/Pictures, reveal in Finder.
on run
\tset repoRoot to (POSIX path of (path to home folder)) & "work/apple"
\tset swiftSrc to repoRoot & "/bin/sal-qr.swift"
\tset swiftBin to repoRoot & "/bin/sal-qr"
\tdo shell script "if [ ! -x " & quoted form of swiftBin & " ] || [ " & quoted form of swiftSrc & " -nt " & quoted form of swiftBin & " ]; then /usr/bin/swiftc -O -o " & quoted form of swiftBin & " " & quoted form of swiftSrc & "; fi"
\tset theText to (the clipboard as text)
\tif theText is "" then
\t\tdisplay dialog "Clipboard is empty." with title "QR My Clipboard" buttons {"OK"} default button "OK"
\t\treturn
\tend if
\tset picPath to (POSIX path of (path to home folder)) & "Pictures/sal-qr-" & (do shell script "date +%Y%m%d-%H%M%S") & ".png"
\tdo shell script quoted form of swiftBin & " " & quoted form of theText & " " & quoted form of picPath
\ttell application "Finder"
\t\tactivate
\t\treveal POSIX file picPath
\tend tell
end run'''),
]

def build(name, applescript):
    unsigned = OUT_DIR / f"{name}.unsigned.shortcut"
    signed = OUT_DIR / f"{name}.shortcut"
    # Wrap in try-on-error so any failure shows a readable display dialog
    # AND logs to ~/Library/Logs/HeySal.log for diagnosis.
    qname = '"' + name.replace('"', '\\"') + '"'  # AppleScript-quoted name
    wrapped = f'''try
{applescript}
on error errMsg number errNum
\tset logPath to (POSIX path of (path to home folder)) & "Library/Logs/HeySal.log"
\ttry
\t\tdo shell script "/bin/echo " & quoted form of ("--- " & ((current date) as text) & " " & {qname} & " ---" & linefeed & "FAILED [" & errNum & "]: " & errMsg) & " >> " & quoted form of logPath
\tend try
\tdisplay dialog ({qname} & " failed:" & linefeed & linefeed & "[" & errNum & "] " & errMsg) with title {qname} buttons {{"OK"}} default button "OK"
end try'''
    plist = {
        'WFWorkflowActions': [{
            'WFWorkflowActionIdentifier': 'is.workflow.actions.runapplescript',
            'WFWorkflowActionParameters': {
                'UUID': str(uuid.uuid4()).upper(),
                'Script': wrapped,
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
    return r.returncode == 0

ok = 0
fail = 0
for name, script in DEMOS:
    if build(name, script):
        print(f"  ✓ {name}")
        ok += 1
    else:
        print(f"  ✗ {name}")
        fail += 1
print(f"\n{ok} built, {fail} failed.")
print(f"Open all: open '{OUT_DIR}'/*.shortcut")
