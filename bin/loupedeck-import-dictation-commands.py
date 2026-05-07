#!/usr/bin/env python3
"""
Phase 4 — Generate a Loupedeck-importable command catalog from CitrusPeel.

Loupedeck Live (and Stream Deck) accept "Custom → AppleScript" actions that point at
a compiled .scpt file path with optional Subroutine + Arguments. This script:

  1. Reads scripts/sal/dictation-commands/commands.json
  2. Groups commands by scope (Keynote, Photos, Numbers, etc.)
  3. Compiles each Sal handler invocation into a one-line .scpt at
     scripts/sal/dictation-commands/loupedeck-buttons/<slug>.scpt
  4. Emits a Loupedeck-importable JSON catalog at
     scripts/sal/dictation-commands/loupedeck-profile.json

Each entry tells the user (or a future automated importer) exactly what to
configure in Loupedeck:
  - Action type: Custom → AppleScript
  - File path: the absolute path to the compiled .scpt
  - Suggested label: Sal's command title
  - Suggested category: Sal's scope (e.g. "Keynote", "Photos")

This realizes WWSD #28 (procedural-vs-task) by making the same task primitive
addressable from THREE input channels: voice (dictation), Spotlight (osacompile
.app), and Loupedeck (hardware button).
"""
import json
import re
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CMD_JSON = ROOT / "scripts/sal/dictation-commands/commands.json"
SCPT_DIR = ROOT / "scripts/sal/dictation-commands/loupedeck-buttons"
PROFILE_JSON = ROOT / "scripts/sal/dictation-commands/loupedeck-profile.json"

SCOPE_TO_LABEL = {
    "com.apple.iWork.Keynote": "Keynote",
    "com.apple.iWork.Pages": "Pages",
    "com.apple.iWork.Numbers": "Numbers",
    "com.apple.Photos": "Photos",
    "com.apple.Maps": "Maps",
    "com.apple.iCal": "Calendar",
    "com.apple.mail": "Mail",
    "com.apple.finder": "Finder",
    "com.apple.QuickTimePlayerX": "QuickTime",
    "com.apple.speech.SystemWideScope": "Global",
}

def slugify(s):
    s = re.sub(r"[^a-zA-Z0-9]+", "-", s).strip("-").lower()
    return s[:80]

def main():
    SCPT_DIR.mkdir(parents=True, exist_ok=True)
    cmds = json.load(open(CMD_JSON))

    catalog = []
    compiled = 0
    failed = 0

    for c in cmds:
        primary = c["phrases"][0] if c["phrases"] else c.get("title", "")
        slug = slugify(c.get("script_file", primary).replace(".scpt", ""))
        if not slug:
            continue
        scpt_path = SCPT_DIR / f"{slug}.scpt"
        src_path = SCPT_DIR / f"{slug}.applescript"
        # The AppleScript body: prepend `use script "DC-XXX"` if needed
        applescript = c["script_text"]
        lib_match = re.search(r'tell script "([^"]+)"', applescript)
        if lib_match and "use script" not in applescript:
            applescript = f'use script "{lib_match.group(1)}"\n{applescript}'
        # Always write source. Compile only succeeds AFTER install (libraries must be in
        # ~/Library/Script Libraries/). On failure, leave source for post-install compile.
        src_path.write_text(applescript)
        try:
            subprocess.run(
                ["osacompile", "-o", str(scpt_path), "-e", applescript],
                check=True, capture_output=True, timeout=10,
            )
            compiled += 1
        except (subprocess.CalledProcessError, subprocess.TimeoutExpired):
            failed += 1
            # source is already written, will compile after Phase 3 install

        scope = c.get("scope", "*")
        category = SCOPE_TO_LABEL.get(scope, "Other")
        catalog.append({
            "slug": slug,
            "label": c.get("title") or primary.title(),
            "category": category,
            "scope_bundle_id": scope,
            "siri_phrase_primary": primary,
            "siri_phrases_all": c["phrases"],
            "scpt_path": str(scpt_path),
            "loupedeck_action": {
                "type": "Custom → AppleScript",
                "file": str(scpt_path),
                "subroutine": "",
                "arguments": "",
            },
            "description": c.get("description", ""),
            "source_library": c.get("script_dir", ""),
        })

    # Sort by category then label
    catalog.sort(key=lambda x: (x["category"], x["label"]))
    PROFILE_JSON.write_text(json.dumps({
        "schema": "loupedeck-dictation-commands-v1",
        "generator": "bin/loupedeck-import-dictation-commands.py",
        "source": "WWDC 2016 session 717 — CitrusPeel255.zip — Sal Soghoian",
        "command_count": len(catalog),
        "categories": sorted(set(c["category"] for c in catalog)),
        "commands": catalog,
    }, indent=2))
    print(f"Compiled {compiled} .scpt files to {SCPT_DIR}")
    print(f"Failed:   {failed}")
    print(f"Catalog:  {PROFILE_JSON}")
    print(f"")
    print(f"Loupedeck import: each catalog entry becomes one button.")
    print(f"  Action type: Custom → AppleScript")
    print(f"  File path:   <scpt_path>")
    print(f"  Label:       <label>")
    print(f"  Group by:    <category>")
    print(f"")
    print(f"For a Stream Deck profile, use the same .scpt files with the AppleScript plugin.")

if __name__ == "__main__":
    main()
