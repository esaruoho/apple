#!/usr/bin/env python3
"""
Capture undocumented Vocal Shortcut JSON shapes for siriRequest and
accessibility action kinds.

Strategy: backup AVSPreferenceKey, watch for changes while the user adds
test entries via the System Settings UI, diff the new entries against the
known siriShortcut shape, and write the captured schemas back into
analysis/sal/vocal-shortcuts-storage-format.md.

This tool does NOT write to AVSPreferenceKey itself. The user must manually
add the test entries through System Settings → Accessibility → Speech →
Vocal Shortcuts, because the only way to generate genuine Apple-formatted
JSON is to let the System Settings UI write it.

Usage:
  python3 bin/capture-vocal-shortcut-schemas.py
  # follow the on-screen prompts; the tool waits for plist changes between steps

The script preserves your existing Vocal Shortcut entries — it only reads
AVSPreferenceKey and diffs successive snapshots.
"""
from __future__ import annotations

import json
import plistlib
import subprocess
import sys
import time
from pathlib import Path

PLIST = Path.home() / "Library/Preferences/com.apple.Accessibility.plist"
PLIST_KEY = "AVSPreferenceKey"


def read_entries() -> list[dict]:
    if not PLIST.exists():
        return []
    # cfprefsd caches the plist; force a flush so we see fresh values
    subprocess.run(["killall", "-HUP", "cfprefsd"], check=False, capture_output=True)
    time.sleep(0.5)
    with open(PLIST, "rb") as f:
        plist = plistlib.load(f)
    blob = plist.get(PLIST_KEY)
    if not blob:
        return []
    if isinstance(blob, bytes):
        return json.loads(blob.decode("utf-8"))
    if isinstance(blob, str):
        return json.loads(blob)
    return blob


def kind_of(entry: dict) -> str:
    t = entry.get("associatedShortcut", {}).get("type", {})
    if not t:
        return "<unknown>"
    return next(iter(t.keys()))


def wait_for_new_entry(before: list[dict], label: str) -> dict | None:
    """Poll AVSPreferenceKey until a new entry appears. Return the new entry."""
    before_ids = {e.get("identifier") for e in before}
    print(f"\n>>> Now waiting for the new entry: {label}")
    print("    Polling every 2 seconds. Press Ctrl-C to abort.")
    start = time.time()
    while True:
        time.sleep(2)
        current = read_entries()
        new = [e for e in current if e.get("identifier") not in before_ids]
        if new:
            print(f"    ✓ detected after {int(time.time() - start)}s")
            return new[0]
        sys.stdout.write(".")
        sys.stdout.flush()


def prompt(text: str) -> None:
    print(f"\n{text}")
    input("    Press ENTER when done... ")


def main() -> int:
    baseline = read_entries()
    print(f"Baseline: {len(baseline)} existing Vocal Shortcut(s)")
    for e in baseline:
        print(f"  - \"{e.get('name')}\" → {kind_of(e)}")

    print("""
This tool captures Apple's JSON shapes for the two unverified action kinds:
  - siriRequest    (a free-form Siri command, e.g. "what time is it")
  - accessibility  (toggle Voice Control / VoiceOver / Zoom / etc.)

You will be prompted to add ONE test Vocal Shortcut of each kind via
System Settings, and to delete each one after capture. Your existing
entries are untouched.

Step 1: open System Settings → Accessibility → Speech → Vocal Shortcuts.
""")
    try:
        subprocess.run(
            ["open", "x-apple.systempreferences:com.apple.Accessibility-Settings.extension"],
            check=False,
        )
    except Exception:
        pass

    captured: dict[str, dict] = {}

    # --- siriRequest ---
    prompt("""Step 2 — Add a TEST entry with Action = "Run a Siri Request":
    1. Click "+" or "Add Vocal Shortcut".
    2. For the phrase, use: __capture test siri request__
    3. For Action, choose "Run a Siri Request" (or similar wording).
    4. Type any Siri command (e.g., "what time is it").
    5. Train the phrase by speaking it 3 times.
    6. Save the new Vocal Shortcut.""")

    entry = wait_for_new_entry(baseline, "siriRequest test")
    if entry:
        captured["siriRequest"] = entry
        print("    Captured JSON:")
        print(json.dumps(entry, indent=2))
    else:
        print("    No new entry detected; skipping siriRequest capture.")

    after_siri = read_entries()

    # --- accessibility ---
    prompt("""Step 3 — Add a TEST entry with Action = an Accessibility toggle:
    1. Click "+" again.
    2. For the phrase, use: __capture test accessibility__
    3. For Action, choose an Accessibility action (Voice Control toggle / Zoom).
    4. Train + save.""")

    entry = wait_for_new_entry(after_siri, "accessibility test")
    if entry:
        captured["accessibility"] = entry
        print("    Captured JSON:")
        print(json.dumps(entry, indent=2))
    else:
        print("    No new entry detected; skipping accessibility capture.")

    # --- cleanup prompt ---
    prompt("""Step 4 — DELETE both test entries from System Settings now.
    Look for the two entries with phrases starting "__capture test".""")

    final = read_entries()
    final_ids = {e.get("identifier") for e in final}
    leftover = [k for k, v in captured.items() if v.get("identifier") in final_ids]
    if leftover:
        print(f"    WARNING: test entries still present: {leftover}")
        print("    Delete them manually to keep your Vocal Shortcuts list clean.")

    # --- write to repo ---
    if not captured:
        print("\nNothing captured. Exiting.")
        return 1

    out_path = Path(__file__).resolve().parent.parent / "analysis/sal/vocal-shortcuts-captured-schemas.json"
    out_path.write_text(json.dumps(captured, indent=2))
    print(f"\nWrote captured shapes to: {out_path}")
    print("Update analysis/sal/vocal-shortcuts-storage-format.md to fold these into the schema doc.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
