#!/usr/bin/env python3
"""
auto-gen.py — Self-assembly tool that reads YAML scripting dictionaries
and auto-generates AppleScript workflow scripts.

Usage:
    python3 bin/auto-gen.py                  # Generate all auto-workflows
    python3 bin/auto-gen.py --app music      # Generate for one app only
    python3 bin/auto-gen.py --list           # Show what would be generated (dry run)
    python3 bin/auto-gen.py --list --app finder

How it works:
    1. Reads YAML dictionaries from dictionaries/<app>/<app>.yaml
    2. For each command and class property, generates a basic workflow script
    3. Outputs to scripts/auto-workflows/<app>/
    4. Skips commands already covered by hand-curated scripts in scripts/workflows/

Sal's rule: one script = one action = one result.
"""

import sys
import os
import re
import argparse
from pathlib import Path

try:
    import yaml
except ImportError:
    print("ERROR: PyYAML required. Install with: pip3 install pyyaml")
    sys.exit(1)

BASE_DIR = Path(__file__).parent.parent
DICT_DIR = BASE_DIR / "dictionaries"
AUTO_DIR = BASE_DIR / "scripts" / "auto-workflows"
HAND_DIR = BASE_DIR / "scripts" / "workflows"

# ─── Target apps (must have <app>/<app>.yaml in dictionaries/) ───────────────

TARGET_APPS = [
    "music",
    "finder",
    "safari",
    "mail",
    "calendar",
    "system-events",
    "reminders",
    "notes",
    "photos",
    "messages",
    "contacts",
    "terminal",
    "textedit",
    "quicktime-player",
    "shortcuts",
]

# ─── Commands that are safe to generate as no-arg actions ────────────────────
# These commands have no required direct_parameter and no required parameters.
# We identify them dynamically from the YAML, but also maintain a blocklist
# of commands that are unsafe or useless to run standalone.

COMMAND_BLOCKLIST = {
    # Dangerous or destructive
    "delete", "close", "move", "save",
    # Need parameters to be useful
    "print", "count", "duplicate", "exists", "make", "open",
    "add", "convert", "download", "export", "refresh", "reveal",
    "search", "select", "set",
    # Internal / obscure
    "abort transaction", "begin transaction", "end transaction",
    "GetURL", "dispatch message to extension", "show extensions preferences",
    "sync all plist to disk", "show credit card settings",
    "attach action to", "attached scripts", "cancel", "confirm",
    "decrement", "do folder action", "edit action of", "increment",
    "key down", "key up", "pick", "remove action from",
    # System Events — need args
    "connect", "disconnect", "click", "key code", "keystroke", "perform",
    "log out", "restart", "shut down", "sleep",
    "start", "stop",
    # Standard suite items that need specifiers
    "data size",
    # Too generic / every app has these — not useful as standalone scripts
    "run", "quit", "activate",
    # Finder specifics already covered by hand-curated scripts
    "copy", "empty", "eject", "sort",
    # Terminal — needs args
    "do script",
    # Contacts — not a real command
    "action property",
    # Calendar — obsolete
    "create calendar",
    # Music — open location needs a URL arg
    "open location",
}

# ─── Properties to skip (generic, useless, or complex types) ────────────────

PROPERTY_BLOCKLIST = {
    "class", "container", "id", "index", "name", "properties",
    "selection",  # complex specifier type
    "clipboard",  # complex specifier
    "current AirPlay devices",  # list type
    "current encoder",  # object type
    "current EQ preset",  # object type
    "current visual",  # object type
    "insertion location",  # specifier
    "startup disk",  # disk object
    "desktop",  # desktop-object
    "trash",  # trash-object
    "home",  # folder object
    "computer container",  # object
    "Finder preferences",  # object
    "data", "raw data",  # binary
    "picture path",  # path
    "home directory",  # path
}

# ─── Types that are safe to read/display as text ────────────────────────────

DISPLAYABLE_TYPES = {"text", "boolean", "integer", "real", "number", "date"}

# ─── Enum types that have a readable string representation ──────────────────

ENUM_DISPLAY_TYPES = {
    "ePlS",  # player state
    "eRpt",  # repeat mode
    "eShM",  # shuffle mode
    "eAPD",  # AirPlay device kind
    "eClS",  # cloud status
    "eRtK",  # rating kind
    "eSrA",  # search area
    "eKnd",  # print kind
    "eExF",  # export format
}


def slugify(name):
    """Convert 'next track' or 'EQ enabled' to 'next-track' or 'eq-enabled'."""
    return re.sub(r'[^a-z0-9]+', '-', name.lower()).strip('-')


def build_covered_set():
    """Scan hand-curated scripts/workflows/ to find what's already covered.

    Returns a set of (app_slug, action_slug) tuples based on filenames.
    e.g. ('music', 'playpause'), ('finder', 'empty-trash')
    """
    covered = set()
    if not HAND_DIR.exists():
        return covered
    for app_dir in HAND_DIR.iterdir():
        if not app_dir.is_dir():
            continue
        app_slug = app_dir.name
        for script in app_dir.glob("*.applescript"):
            # filename: music-playpause.applescript -> action = playpause
            stem = script.stem
            prefix = f"{app_slug}-"
            if stem.startswith(prefix):
                action = stem[len(prefix):]
            else:
                action = stem
            covered.add((app_slug, action))
    return covered


def is_no_arg_command(cmd):
    """Check if a command can be called with no arguments."""
    # Has a required direct_parameter?
    dp = cmd.get("direct_parameter")
    if dp and not dp.get("optional", True):
        return False
    # Has any required parameters?
    for p in cmd.get("parameters", []):
        if not p.get("optional", True):
            return False
    return True


def load_app_yaml(app_slug):
    """Load and return the YAML dictionary for an app."""
    yaml_path = DICT_DIR / app_slug / f"{app_slug}.yaml"
    if not yaml_path.exists():
        return None
    try:
        with open(yaml_path) as f:
            return yaml.safe_load(f)
    except yaml.YAMLError as e:
        print(f"  WARNING: Could not parse {yaml_path.name}: {e}")
        return None


def make_header(description, app_name, action_slug, app_slug):
    """Generate the standard header comment block."""
    lines = [
        f"-- {description}",
        f"-- App: {app_name}",
        f"-- Usage: osascript scripts/auto-workflows/{app_slug}/{app_slug}-{action_slug}.applescript",
        f"-- Auto-generated by auto-gen.py",
    ]
    return "\n".join(lines)


def gen_no_arg_command(app_name, app_slug, cmd_name, cmd_desc):
    """Generate script for a no-arg action command (playpause, stop, etc.)."""
    action_slug = slugify(cmd_name)
    description = cmd_desc or f"{cmd_name}"
    # Capitalize first letter of description
    description = description[0].upper() + description[1:] if description else cmd_name

    header = make_header(description, app_name, action_slug, app_slug)
    body = f"""
-- Concept: tell application ... end tell
--   Sends Apple Events to an app. The app must have a scripting dictionary (sdef).

tell application "{app_name}"
    {cmd_name}
end tell
display notification "Done" with title "{app_name}: {cmd_name}"
"""
    return action_slug, header + body


def gen_property_getter(app_name, app_slug, prop_name, prop_type, context=None):
    """Generate script for a read-only property getter."""
    action_slug = slugify(f"get-{prop_name}")
    desc_context = f" of {context}" if context else ""
    description = f"Get {prop_name}{desc_context}"

    header = make_header(description, app_name, action_slug, app_slug)

    # How to coerce to string depends on type
    if prop_type in ("text",):
        coerce = ""
    elif prop_type in ("boolean",):
        coerce = " as text"
    elif prop_type in ("integer", "real", "number"):
        coerce = " as text"
    elif prop_type in ("date",):
        coerce = " as text"
    elif prop_type in ENUM_DISPLAY_TYPES:
        coerce = " as text"
    else:
        coerce = " as text"

    if context:
        getter = f'set val to {prop_name} of {context}{coerce}'
    else:
        getter = f'set val to {prop_name}{coerce}'

    body = f"""
-- Concept: tell application ... end tell
--   Sends Apple Events to an app. The app must have a scripting dictionary (sdef).
-- Concept: display dialog "text"
--   Shows a modal dialog with text and buttons. Blocks until user responds.

tell application "{app_name}"
    {getter}
    display dialog "{prop_name}: " & val with title "{app_name}" buttons {{"OK"}} default button "OK"
end tell
"""
    return action_slug, header + body


def gen_property_toggle(app_name, app_slug, prop_name, context=None):
    """Generate script for toggling a boolean property."""
    action_slug = slugify(f"toggle-{prop_name}")
    description = f"Toggle {prop_name}"

    header = make_header(description, app_name, action_slug, app_slug)

    if context:
        getter = f'{prop_name} of {context}'
        setter = f'set {prop_name} of {context} to not {prop_name} of {context}'
    else:
        getter = f'{prop_name}'
        setter = f'set {prop_name} to not {prop_name}'

    body = f"""
-- Concept: tell application ... end tell
--   Sends Apple Events to an app. The app must have a scripting dictionary (sdef).
-- Concept: display notification "text" with title "title"
--   Shows a macOS notification banner. Disappears after a few seconds.

tell application "{app_name}"
    {setter}
    if {getter} then
        display notification "{prop_name}: ON" with title "{app_name}"
    else
        display notification "{prop_name}: OFF" with title "{app_name}"
    end if
end tell
"""
    return action_slug, header + body


def gen_property_set_integer(app_name, app_slug, prop_name, context=None):
    """Generate script for setting an integer/real property via dialog prompt."""
    action_slug = slugify(f"set-{prop_name}")
    description = f"Set {prop_name} via dialog prompt"

    header = make_header(description, app_name, action_slug, app_slug)

    if context:
        getter = f'{prop_name} of {context}'
        setter_tpl = f'set {prop_name} of {context} to newVal'
    else:
        getter = f'{prop_name}'
        setter_tpl = f'set {prop_name} to newVal'

    body = f"""
-- Concept: tell application ... end tell
--   Sends Apple Events to an app. The app must have a scripting dictionary (sdef).
-- Concept: display dialog "text" default answer "text"
--   Shows a dialog with a text input field. Returns user input.

tell application "{app_name}"
    set currentVal to {getter}
    set userInput to display dialog "Set {prop_name}:" default answer (currentVal as text) with title "{app_name}" buttons {{"Cancel", "OK"}} default button "OK"
    set newVal to (text returned of userInput) as number
    {setter_tpl}
    display notification "{prop_name}: " & newVal with title "{app_name}"
end tell
"""
    return action_slug, header + body


def gen_property_set_text(app_name, app_slug, prop_name, context=None):
    """Generate script for setting a text property via dialog prompt."""
    action_slug = slugify(f"set-{prop_name}")
    description = f"Set {prop_name} via dialog prompt"

    header = make_header(description, app_name, action_slug, app_slug)

    if context:
        getter = f'{prop_name} of {context}'
        setter_tpl = f'set {prop_name} of {context} to newVal'
    else:
        getter = f'{prop_name}'
        setter_tpl = f'set {prop_name} to newVal'

    body = f"""
-- Concept: tell application ... end tell
--   Sends Apple Events to an app. The app must have a scripting dictionary (sdef).
-- Concept: display dialog "text" default answer "text"
--   Shows a dialog with a text input field. Returns user input.

tell application "{app_name}"
    set currentVal to {getter}
    set userInput to display dialog "Set {prop_name}:" default answer currentVal with title "{app_name}" buttons {{"Cancel", "OK"}} default button "OK"
    set newVal to text returned of userInput
    {setter_tpl}
    display notification "{prop_name}: " & newVal with title "{app_name}"
end tell
"""
    return action_slug, header + body


def context_for_class(app_slug, class_name):
    """Return the AppleScript context expression for a class, or None to skip."""
    if class_name == "application":
        return None  # application-level properties need no context
    if class_name == "track" and app_slug == "music":
        return "current track"
    if class_name in ("document", "rich text"):
        return "front document"
    if class_name == "tab" and app_slug == "safari":
        return "current tab of front window"
    if class_name == "window":
        return "front window"
    # Skip classes that need element specifiers we can't generate safely
    return "__SKIP__"


# ─── Classes worth generating property scripts for ──────────────────────────

INTERESTING_CLASSES = {
    "music": ["application", "track"],
    "finder": ["application"],
    "safari": ["tab"],
    "mail": [],  # Mail has no application class in sdef; skip
    "calendar": [],  # No simple application properties
    "system-events": ["appearance preferences object", "dock preferences object"],
    "reminders": [],
    "notes": [],
    "photos": [],
    "messages": [],
    "contacts": [],
    "terminal": [],
    "textedit": [],
    "quicktime-player": [],
    "shortcuts": [],
}

# ─── Limit track properties to the most useful ones ─────────────────────────
# Without this, we'd generate 70+ scripts for every track metadata field.

TRACK_PROPERTY_ALLOWLIST = {
    "album", "artist", "album artist", "bit rate", "bpm", "comment",
    "composer", "date added", "disc number", "duration", "enabled",
    "genre", "loved", "disliked", "favorited", "played count",
    "played date", "rating", "sample rate", "size", "track count",
    "track number", "year",
}

# ─── Context expressions for special classes ────────────────────────────────

CLASS_CONTEXTS = {
    ("system-events", "appearance preferences object"): "appearance preferences",
    ("system-events", "dock preferences object"): "dock preferences",
}


def generate_for_app(app_slug, covered, dry_run=False):
    """Generate auto-workflow scripts for one app.

    Returns (generated_count, skipped_count, scripts_list).
    """
    data = load_app_yaml(app_slug)
    if data is None:
        return 0, 0, []

    app_name = data.get("app", app_slug.title())
    generated = 0
    skipped = 0
    scripts = []

    output_dir = AUTO_DIR / app_slug
    if not dry_run:
        output_dir.mkdir(parents=True, exist_ok=True)

    # ── 1. No-arg commands ──────────────────────────────────────────────────

    for suite in data.get("suites", []):
        for cmd in suite.get("commands", []):
            cmd_name = cmd.get("name", "")
            cmd_desc = cmd.get("description", "")

            # Skip blocklisted commands
            if cmd_name in COMMAND_BLOCKLIST:
                continue

            # Only generate for no-arg commands
            if not is_no_arg_command(cmd):
                continue

            action_slug = slugify(cmd_name)

            # Check if already covered by hand-curated script
            if (app_slug, action_slug) in covered:
                skipped += 1
                continue

            result = gen_no_arg_command(app_name, app_slug, cmd_name, cmd_desc)
            if result:
                action_slug, script_text = result
                # Double-check after generation
                if (app_slug, action_slug) in covered:
                    skipped += 1
                    continue

                filename = f"{app_slug}-{action_slug}.applescript"
                filepath = output_dir / filename
                scripts.append((filepath, script_text, cmd_desc or cmd_name))

                if not dry_run:
                    filepath.write_text(script_text)
                generated += 1

    # ── 2. Property getters/setters from interesting classes ────────────────

    interesting = INTERESTING_CLASSES.get(app_slug, [])
    if not interesting:
        return generated, skipped, scripts

    # Build a lookup of class definitions
    class_map = {}
    for suite in data.get("suites", []):
        for cls in suite.get("classes", []):
            class_map[cls["name"]] = cls

    for class_name in interesting:
        cls = class_map.get(class_name)
        if cls is None:
            continue

        # Determine context
        ctx_key = (app_slug, class_name)
        if ctx_key in CLASS_CONTEXTS:
            context = CLASS_CONTEXTS[ctx_key]
        else:
            context = context_for_class(app_slug, class_name)

        if context == "__SKIP__":
            continue

        for prop in cls.get("properties", []):
            prop_name = prop.get("name", "")
            prop_type = prop.get("type", "")
            prop_access = prop.get("access", "r")

            # Skip blocklisted/undisplayable properties
            if prop_name in PROPERTY_BLOCKLIST:
                continue

            # For track properties (Music), only allow curated subset
            if class_name == "track" and prop_name not in TRACK_PROPERTY_ALLOWLIST:
                continue

            # Skip types we can't display
            if prop_type not in DISPLAYABLE_TYPES and prop_type not in ENUM_DISPLAY_TYPES:
                continue

            # Skip empty types
            if not prop_type:
                continue

            # ── Read-only property → getter ──
            if prop_access == "r":
                action_slug = slugify(f"get-{prop_name}")
                if (app_slug, action_slug) in covered:
                    skipped += 1
                    continue

                result = gen_property_getter(app_name, app_slug, prop_name, prop_type, context)
                if result:
                    action_slug, script_text = result
                    if (app_slug, action_slug) in covered:
                        skipped += 1
                        continue
                    filename = f"{app_slug}-{action_slug}.applescript"
                    filepath = output_dir / filename
                    scripts.append((filepath, script_text, f"Get {prop_name}"))
                    if not dry_run:
                        filepath.write_text(script_text)
                    generated += 1

            # ── Read-write property → getter + setter/toggle ──
            elif prop_access == "rw":
                # Generate getter
                action_slug = slugify(f"get-{prop_name}")
                if (app_slug, action_slug) not in covered:
                    result = gen_property_getter(app_name, app_slug, prop_name, prop_type, context)
                    if result:
                        action_slug, script_text = result
                        if (app_slug, action_slug) not in covered:
                            filename = f"{app_slug}-{action_slug}.applescript"
                            filepath = output_dir / filename
                            scripts.append((filepath, script_text, f"Get {prop_name}"))
                            if not dry_run:
                                filepath.write_text(script_text)
                            generated += 1
                        else:
                            skipped += 1
                else:
                    skipped += 1

                # Generate setter/toggle
                if prop_type == "boolean":
                    action_slug = slugify(f"toggle-{prop_name}")
                    if (app_slug, action_slug) in covered:
                        skipped += 1
                        continue
                    result = gen_property_toggle(app_name, app_slug, prop_name, context)
                elif prop_type in ("integer", "real", "number"):
                    action_slug = slugify(f"set-{prop_name}")
                    if (app_slug, action_slug) in covered:
                        skipped += 1
                        continue
                    result = gen_property_set_integer(app_name, app_slug, prop_name, context)
                elif prop_type == "text":
                    action_slug = slugify(f"set-{prop_name}")
                    if (app_slug, action_slug) in covered:
                        skipped += 1
                        continue
                    result = gen_property_set_text(app_name, app_slug, prop_name, context)
                else:
                    continue

                if result:
                    action_slug, script_text = result
                    if (app_slug, action_slug) in covered:
                        skipped += 1
                        continue
                    filename = f"{app_slug}-{action_slug}.applescript"
                    filepath = output_dir / filename
                    scripts.append((filepath, script_text, f"Set/toggle {prop_name}"))
                    if not dry_run:
                        filepath.write_text(script_text)
                    generated += 1

    return generated, skipped, scripts


def main():
    parser = argparse.ArgumentParser(description="Auto-generate AppleScript workflows from YAML dictionaries")
    parser.add_argument("--list", action="store_true", help="Dry run: show what would be generated")
    parser.add_argument("--app", type=str, help="Generate for one app only (e.g. music, finder)")
    args = parser.parse_args()

    dry_run = args.list

    # Determine which apps to process
    if args.app:
        app_slug = args.app.lower().replace(" ", "-")
        if app_slug not in TARGET_APPS:
            # Try anyway — it might have a YAML dictionary
            apps = [app_slug]
        else:
            apps = [app_slug]
    else:
        apps = TARGET_APPS

    # Build the set of already-covered scripts
    covered = build_covered_set()

    total_generated = 0
    total_skipped = 0
    total_apps = 0

    for app_slug in apps:
        yaml_path = DICT_DIR / app_slug / f"{app_slug}.yaml"
        if not yaml_path.exists():
            continue

        gen_count, skip_count, scripts = generate_for_app(app_slug, covered, dry_run=dry_run)

        if gen_count > 0 or skip_count > 0:
            total_apps += 1

        if gen_count > 0:
            if dry_run:
                print(f"\n{'─' * 60}")
                print(f"  {app_slug} — {gen_count} scripts would be generated ({skip_count} skipped)")
                print(f"{'─' * 60}")
                for filepath, _, desc in scripts:
                    print(f"  {filepath.name:50s} {desc}")
            else:
                print(f"  {app_slug}: generated {gen_count} scripts ({skip_count} skipped)")

        total_generated += gen_count
        total_skipped += skip_count

    # Summary
    print()
    if dry_run:
        print(f"Generated {total_generated} auto-scripts across {total_apps} apps ({total_skipped} skipped as already covered)")
        print("(dry run — no files written)")
    else:
        if total_generated > 0:
            print(f"Generated {total_generated} auto-scripts across {total_apps} apps ({total_skipped} skipped as already covered)")
            print(f"Output: {AUTO_DIR}/")
        else:
            print("No new scripts to generate (all covered by hand-curated workflows).")


if __name__ == "__main__":
    main()
