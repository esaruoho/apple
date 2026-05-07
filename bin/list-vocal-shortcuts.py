#!/usr/bin/env python3
"""
Read Vocal Shortcuts entries from macOS Sequoia (Apple Silicon).

Storage path discovered empirically 2026-05-07:
  ~/Library/Preferences/com.apple.Accessibility.plist
  → key AVSPreferenceKey
  → UTF-8 JSON array

Each entry shape:
  {
    "name": "<spoken phrase>",
    "associatedShortcut": {
      "name": "<Shortcut name from Shortcuts.app>",
      "type": {"siriShortcut": {"id": "<Shortcut UUID>"}},
      "id": "<internal id>"
    },
    "identifier": "<Vocal Shortcut entry UUID>"
  }

This makes Vocal Shortcuts a first-class part of the apple-skill automation
inventory — alongside scripts, Shortcuts, and Loupedeck buttons.
"""
import json
import plistlib
import sys
from pathlib import Path

PLIST = Path.home() / "Library/Preferences/com.apple.Accessibility.plist"
KEY = "AVSPreferenceKey"

def read_entries():
    if not PLIST.exists():
        return []
    with open(PLIST, "rb") as f:
        plist = plistlib.load(f)
    blob = plist.get(KEY)
    if not blob:
        return []
    if isinstance(blob, bytes):
        try:
            return json.loads(blob.decode("utf-8"))
        except json.JSONDecodeError as e:
            print(f"ERROR: AVSPreferenceKey is not valid JSON: {e}", file=sys.stderr)
            return []
    if isinstance(blob, str):
        return json.loads(blob)
    return blob

def render(entries):
    if not entries:
        print("(no Vocal Shortcuts configured)")
        return
    print(f"{len(entries)} Vocal Shortcut(s):")
    for e in entries:
        phrase = e.get("name", "?")
        sc = e.get("associatedShortcut", {})
        sc_name = sc.get("name", "?")
        sc_type = sc.get("type", {})
        if "siriShortcut" in sc_type:
            kind = "Shortcut"
            sc_id = sc_type["siriShortcut"].get("id", "?")
        elif "siriRequest" in sc_type:
            kind = "Siri Request"
            sc_id = sc_type["siriRequest"].get("id", "?") if isinstance(sc_type["siriRequest"], dict) else ""
        elif "accessibility" in sc_type:
            kind = "Accessibility"
            sc_id = ""
        else:
            kind = list(sc_type.keys())[0] if sc_type else "?"
            sc_id = ""
        print(f'  "{phrase}" → [{kind}] {sc_name}  ({sc_id})')

def main():
    entries = read_entries()
    if "--json" in sys.argv:
        print(json.dumps(entries, indent=2))
    else:
        render(entries)

if __name__ == "__main__":
    main()
