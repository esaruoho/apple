#!/usr/bin/env python3
"""
shortcut-gen.py — Generate signed .shortcut files from AppleScript workflow scripts.

Usage:
    python3 bin/shortcut-gen.py                      # Generate all shortcuts
    python3 bin/shortcut-gen.py finder                # Generate for one app
    python3 bin/shortcut-gen.py --install             # Generate + open for import
    python3 bin/shortcut-gen.py --install finder      # Generate + open for one app
    python3 bin/shortcut-gen.py --list                # List what would be generated
    python3 bin/shortcut-gen.py --folder "My Folder"  # Set Shortcuts folder name

Output:
    shortcuts/<app>/<Shortcut-Name>.shortcut (signed, importable)

Each .shortcut wraps a workflow AppleScript in a "Run AppleScript" action.
Once imported, they're reachable via Siri, Spotlight, share sheet, and menu bar.

Pipeline: workflow-gen.py -> shortcut-gen.py -> Siri/Spotlight
"""

import plistlib
import subprocess
import sys
import os
from pathlib import Path

WORKFLOWS_DIR = Path(__file__).parent.parent / "scripts" / "workflows"
SHORTCUTS_DIR = Path(__file__).parent.parent / "shortcuts"

# Icon glyphs and colors for different app categories
# Glyph numbers from SF Symbols used by Shortcuts
APP_ICONS = {
    "finder":         {"glyph": 59493, "color": 463140863},   # blue, folder
    "music":          {"glyph": 59452, "color": 4292093695},   # pink, music note
    "mail":           {"glyph": 59422, "color": 431817727},    # blue, envelope
    "safari":         {"glyph": 59511, "color": 440166399},    # blue, compass
    "notes":          {"glyph": 59538, "color": 4294222079},   # yellow, note
    "reminders":      {"glyph": 59496, "color": 463140863},    # blue, checklist
    "calendar":       {"glyph": 59434, "color": 4282601983},   # red, calendar
    "photos":         {"glyph": 59470, "color": 4282601983},   # red, photo
    "messages":       {"glyph": 59428, "color": 1440546815},   # green, bubble
    "contacts":       {"glyph": 59438, "color": 3679049983},   # gray, person
    "terminal":       {"glyph": 59511, "color": 255},          # black, terminal
    "system-events":  {"glyph": 59458, "color": 3679049983},   # gray, gear
    "shortcuts":      {"glyph": 59511, "color": 4282601983},   # red, shortcuts
    "textedit":       {"glyph": 59538, "color": 3679049983},   # gray, doc
    "quicktime":      {"glyph": 59452, "color": 463140863},    # blue, play
    "homepod":        {"glyph": 59458, "color": 4292093695},   # pink, speaker
}

DEFAULT_ICON = {"glyph": 59511, "color": 4282601983}


def read_applescript(script_path):
    """Read an AppleScript file, skip the header comments."""
    lines = script_path.read_text().split('\n')
    # Skip header lines (starting with --)
    code_lines = []
    past_header = False
    for line in lines:
        if not past_header and line.startswith('--'):
            continue
        if not past_header and line.strip() == '':
            continue
        past_header = True
        code_lines.append(line)
    return '\n'.join(code_lines).strip()


def get_description(script_path):
    """Get the description from the first line of the script."""
    first_line = script_path.read_text().split('\n')[0]
    if first_line.startswith('-- '):
        return first_line[3:]
    return script_path.stem


def build_shortcut_plist(name, applescript_code, icon_config):
    """Build a .shortcut plist with a Run AppleScript action."""
    return {
        'WFWorkflowActions': [
            {
                'WFWorkflowActionIdentifier': 'is.workflow.actions.runscript',
                'WFWorkflowActionParameters': {
                    'WFScriptActionScript': applescript_code,
                },
            }
        ],
        'WFWorkflowClientVersion': '2612.0.4',
        'WFWorkflowHasOutputFallback': False,
        'WFWorkflowHasShortcutInputVariables': False,
        'WFWorkflowIcon': {
            'WFWorkflowIconGlyphNumber': icon_config.get('glyph', 59511),
            'WFWorkflowIconStartColor': icon_config.get('color', 4282601983),
        },
        'WFWorkflowImportQuestions': [],
        'WFWorkflowInputContentItemClasses': [
            'WFStringContentItem',
        ],
        'WFWorkflowMinimumClientVersion': 900,
        'WFWorkflowMinimumClientVersionString': '900',
        'WFWorkflowOutputContentItemClasses': [],
        'WFWorkflowTypes': [],
    }


def sign_shortcut(unsigned_path, signed_path):
    """Sign a .shortcut file using the shortcuts CLI."""
    result = subprocess.run(
        ['shortcuts', 'sign', '--mode', 'anyone',
         '--input', str(unsigned_path), '--output', str(signed_path)],
        capture_output=True, text=True
    )
    return result.returncode == 0


def shortcut_name_from_script(script_path):
    """Convert script filename to a nice Shortcut name.
    finder-copy-path.applescript -> Finder Copy Path
    """
    stem = script_path.stem  # e.g., "finder-copy-path"
    return stem.replace('-', ' ').title()


def main():
    args = sys.argv[1:]

    install = '--install' in args
    args = [a for a in args if a != '--install']

    folder_name = 'Apple Workflows'
    if '--folder' in args:
        idx = args.index('--folder')
        if idx + 1 < len(args):
            folder_name = args[idx + 1]
            args = args[:idx] + args[idx+2:]

    if '--list' in args:
        print("Shortcuts that would be generated:\n")
        for app_dir in sorted(WORKFLOWS_DIR.iterdir()):
            if not app_dir.is_dir():
                continue
            scripts = sorted(app_dir.glob("*.applescript"))
            if scripts:
                app_display = app_dir.name.replace('-', ' ').title()
                print(f"  {app_display}:")
                for s in scripts:
                    print(f"    {shortcut_name_from_script(s)}")
        return

    # Filter apps
    filter_apps = [a.lower().replace(' ', '-') for a in args]

    SHORTCUTS_DIR.mkdir(parents=True, exist_ok=True)

    print("═══ Shortcut Generator ═══")
    print(f"Source:    {WORKFLOWS_DIR}")
    print(f"Output:    {SHORTCUTS_DIR}")
    if install:
        print(f"Mode:      Generate + Install")
    print()

    total = 0
    errors = 0
    generated_files = []

    for app_dir in sorted(WORKFLOWS_DIR.iterdir()):
        if not app_dir.is_dir():
            continue
        app_slug = app_dir.name

        if filter_apps and app_slug not in filter_apps:
            continue

        app_display = app_slug.replace('-', ' ').title()
        icon_config = APP_ICONS.get(app_slug, DEFAULT_ICON)

        out_dir = SHORTCUTS_DIR / app_slug
        out_dir.mkdir(parents=True, exist_ok=True)

        print(f"  {app_display}:")

        for script_path in sorted(app_dir.glob("*.applescript")):
            name = shortcut_name_from_script(script_path)
            code = read_applescript(script_path)
            desc = get_description(script_path)

            # Build plist
            plist_data = build_shortcut_plist(name, code, icon_config)

            # Write unsigned
            unsigned = out_dir / f"{script_path.stem}.unsigned.shortcut"
            with open(unsigned, 'wb') as f:
                plistlib.dump(plist_data, f, fmt=plistlib.FMT_BINARY)

            # Sign
            signed = out_dir / f"{script_path.stem}.shortcut"
            if sign_shortcut(unsigned, signed):
                unsigned.unlink()  # Clean up unsigned
                print(f"    {name}")
                generated_files.append(signed)
                total += 1
            else:
                print(f"    {name} [SIGN ERROR]")
                unsigned.unlink(missing_ok=True)
                errors += 1

    print(f"\n  Generated: {total} shortcuts ({errors} errors)")

    if install and generated_files:
        print(f"\n  Opening {len(generated_files)} shortcuts for import...")
        print(f"  You'll need to tap 'Add Shortcut' for each one.")
        print(f"  Tip: Move them to folder '{folder_name}' after import.")
        print()
        for f in generated_files:
            subprocess.run(['open', str(f)])
            # Small delay to not overwhelm the UI
            import time
            time.sleep(0.5)

    print(f"\n═══ Done: {total} shortcuts across {len(list(SHORTCUTS_DIR.iterdir()))} apps ═══")
    if not install:
        print(f"Run with --install to open for import into Shortcuts app.")


if __name__ == '__main__':
    main()
