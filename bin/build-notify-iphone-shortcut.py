#!/usr/bin/env python3
"""
Build a signed iOS-compatible Shortcut: "Notify iPhone from iCloud".

This Shortcut is the body of the iPhone-side notify pipeline. Once installed
on the iPhone, it accepts a file (a JSON dropped into iCloud Drive's
notify-iphone/ folder), parses it, and shows a notification with the
title/body fields.

After importing on iPhone:
  Shortcuts → Automation → New Personal Automation →
    When File is Added to Folder = iCloud Drive / notify-iphone →
    Run Shortcut → "Notify iPhone from iCloud" → Run Immediately ✓

That's the whole setup. Two taps post-import.

The Shortcut uses iOS-native actions only (no AppleScript escape hatch — that
only works on macOS). Action chain:
  1. Get Dictionary from Input         — parse the file's JSON
  2. Get Dictionary Value (key=title)  — magic-var input ← step 1
  3. Get Dictionary Value (key=body)   — magic-var input ← step 1
  4. Show Notification                 — title ← step 2, body ← step 3

Output: shortcuts/iphone/Notify iPhone from iCloud.shortcut  (signed)

iPhone install: AirDrop, iMessage, or save to iCloud Drive and tap.
"""
import plistlib
import subprocess
import sys
import uuid
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT_DIR = ROOT / "shortcuts/iphone"
OUT_DIR.mkdir(parents=True, exist_ok=True)

NAME = "Notify iPhone from iCloud"


def new_uuid() -> str:
    return str(uuid.uuid4()).upper()


def magic_var(source_uuid: str, output_name: str) -> dict:
    """
    A WFTextTokenString that references another action's output as a magic
    variable. The U+FFFC ('OBJECT REPLACEMENT CHARACTER') is the placeholder
    Shortcuts substitutes the variable for at runtime.
    """
    return {
        "WFSerializationType": "WFTextTokenString",
        "Value": {
            "string": "￼",
            "attachmentsByRange": {
                "{0, 1}": {
                    "Type": "ActionOutput",
                    "OutputUUID": source_uuid,
                    "OutputName": output_name,
                }
            },
        },
    }


# UUIDs for actions whose output we'll reference later.
DICT_UUID  = new_uuid()
TITLE_UUID = new_uuid()
BODY_UUID  = new_uuid()

actions = [
    # 1. Parse the input file's contents as a dictionary (JSON).
    {
        "WFWorkflowActionIdentifier": "is.workflow.actions.detect.dictionary",
        "WFWorkflowActionParameters": {
            "UUID": DICT_UUID,
            "CustomOutputName": "Dictionary",
        },
    },
    # 2. Extract "title" from the dictionary.
    {
        "WFWorkflowActionIdentifier": "is.workflow.actions.getvalueforkey",
        "WFWorkflowActionParameters": {
            "UUID": TITLE_UUID,
            "CustomOutputName": "Title",
            "WFGetDictionaryValueType": "Value",
            "WFDictionaryKey": "title",
            "WFInput": magic_var(DICT_UUID, "Dictionary"),
        },
    },
    # 3. Extract "body" from the dictionary.
    {
        "WFWorkflowActionIdentifier": "is.workflow.actions.getvalueforkey",
        "WFWorkflowActionParameters": {
            "UUID": BODY_UUID,
            "CustomOutputName": "Body",
            "WFGetDictionaryValueType": "Value",
            "WFDictionaryKey": "body",
            "WFInput": magic_var(DICT_UUID, "Dictionary"),
        },
    },
    # 4. Show iOS notification with the parsed title/body.
    {
        "WFWorkflowActionIdentifier": "is.workflow.actions.notification",
        "WFWorkflowActionParameters": {
            "UUID": new_uuid(),
            "WFNotificationActionTitle": magic_var(TITLE_UUID, "Title"),
            "WFNotificationActionBody":  magic_var(BODY_UUID,  "Body"),
            "WFNotificationActionSound": True,
        },
    },
]

plist = {
    "WFWorkflowActions": actions,
    "WFWorkflowClientVersion": "2612.0.4",
    "WFWorkflowHasOutputFallback": False,
    "WFWorkflowHasShortcutInputVariables": True,
    "WFWorkflowIcon": {
        "WFWorkflowIconGlyphNumber":  61440 + 1023,   # bell-ish
        "WFWorkflowIconStartColor":   4292311079,     # orange
    },
    "WFWorkflowImportQuestions": [],
    # Accept any file type — the Personal Automation feeds in the .json that
    # landed in iCloud Drive/notify-iphone/.
    "WFWorkflowInputContentItemClasses": [
        "WFGenericFileContentItem",
    ],
    "WFWorkflowMinimumClientVersion": 900,
    "WFWorkflowMinimumClientVersionString": "900",
    "WFWorkflowOutputContentItemClasses": [],
    # Runs on iPhone, iPad, Mac. No Quick-Action surfaces — it's invoked by
    # the Personal Automation, not from a context menu.
    "WFWorkflowTypes": [],
}

unsigned = OUT_DIR / f"{NAME}.unsigned.shortcut"
signed   = OUT_DIR / f"{NAME}.shortcut"

with unsigned.open("wb") as f:
    plistlib.dump(plist, f, fmt=plistlib.FMT_BINARY)

result = subprocess.run(
    ["shortcuts", "sign", "--mode", "anyone",
     "--input", str(unsigned), "--output", str(signed)],
    capture_output=True, text=True,
)
if result.returncode != 0:
    sys.exit(f"sign failed: {result.stderr}")
unsigned.unlink()

print(f"Built: {signed}")
print()
print("Send to your iPhone:")
print(f"  bin/imessage-send-file '{signed}' esaruoho@gmail.com")
print()
print("Or AirDrop / iCloud Drive / drag to Messages chat.")
print()
print("On iPhone, after import:")
print("  Shortcuts → Automation → + → New Personal Automation")
print("  → When File is Added to Folder = iCloud Drive/notify-iphone")
print("  → Run Shortcut → 'Notify iPhone from iCloud'")
print("  → Run Immediately ✓")
