#!/usr/bin/env python3
"""
Emit a flat newline-separated list of all command phrases known to Sal's Siri.
Used by the "Hey Sal" Shortcut's choose-from-list picker.

Layout (top to bottom):
  - Sal command primary phrases (588 entries)  — sorted alphabetically
  - --- separator ---
  - User's own Shortcuts                        — sorted alphabetically
"""
import json
from pathlib import Path

SAL = Path.home() / "Library/Application Support/Sal-Siri/intents.json"
USER = Path.home() / "Library/Application Support/Sal-Siri/user-shortcuts.json"

def main():
    out = []
    if SAL.exists():
        sal = json.load(open(SAL))
        sal_phrases = sorted(set(i.get("primary_phrase","").strip() for i in sal if i.get("primary_phrase")))
        out.extend(sal_phrases)
    if USER.exists():
        try:
            user = json.load(open(USER))
            user_names = sorted(set(s["name"].strip() for s in user if s.get("name")))
            if user_names:
                out.append("─── Your Shortcuts ───")
                out.extend(user_names)
        except Exception:
            pass
    print("\n".join(out))

if __name__ == "__main__":
    main()
