#!/usr/bin/env python3
"""
sdef-extract.py — Extract Apple app scripting dictionaries to markdown + YAML knowledge files.

Usage:
    python3 sdef-extract.py                     # Extract all scriptable Apple apps
    python3 sdef-extract.py Finder              # Extract single app
    python3 sdef-extract.py Finder Mail Safari   # Extract specific apps
    python3 sdef-extract.py --list              # List all scriptable apps

Output:
    dictionaries/
    ├── finder/
    │   ├── finder.yaml          # Machine-readable: commands, classes, properties
    │   ├── finder.md            # Human-readable: full scripting reference
    │   └── finder-examples.md   # AppleScript examples for each command
    ├── mail/
    │   ├── mail.yaml
    │   ├── mail.md
    │   └── mail-examples.md
    └── _index.yaml              # Master index of all apps + their data types (for chaining)

Inspired by Sal Soghoian's patent US 7,428,535 — Automatic Relevance Filtering.
The _index.yaml maps input/output data types across apps, enabling Automator-style chaining.
"""

import subprocess
import sys
import os
import xml.etree.ElementTree as ET
from pathlib import Path
import json
import re

# ─── App Registry ──────────────────────────────────────────────────────────────
# Maps app name -> sdef path (discovered by probing)
APP_PATHS = {
    # CoreServices (hidden powerhouses)
    "Finder": "/System/Library/CoreServices/Finder.app",
    "System Events": "/System/Library/CoreServices/System Events.app",
    "Image Events": "/System/Library/CoreServices/Image Events.app",
    # System Apps
    "Mail": "/System/Applications/Mail.app",
    "Safari": "/Applications/Safari.app",
    "Music": "/System/Applications/Music.app",
    "Photos": "/System/Applications/Photos.app",
    "Notes": "/System/Applications/Notes.app",
    "Reminders": "/System/Applications/Reminders.app",
    "Calendar": "/System/Applications/Calendar.app",
    "Contacts": "/System/Applications/Contacts.app",
    "Messages": "/System/Applications/Messages.app",
    "TV": "/System/Applications/TV.app",
    "TextEdit": "/System/Applications/TextEdit.app",
    "Preview": "/System/Applications/Preview.app",
    "QuickTime Player": "/System/Applications/QuickTime Player.app",
    "Automator": "/System/Applications/Automator.app",
    "Shortcuts": "/System/Applications/Shortcuts.app",
    "System Settings": "/System/Applications/System Settings.app",
    # iWork
    "Keynote": "/Applications/Keynote.app",
    "Numbers": "/Applications/Numbers.app",
    "Pages": "/Applications/Pages.app",
    # Pro Apps
    "Final Cut Pro": "/Applications/Final Cut Pro.app",
    "Logic Pro": "/Applications/Logic Pro.app",
    "iMovie": "/Applications/iMovie.app",
    # Utilities
    "Terminal": "/System/Applications/Utilities/Terminal.app",
    "Script Editor": "/System/Applications/Utilities/Script Editor.app",
    "Console": "/System/Applications/Utilities/Console.app",
    "System Information": "/System/Applications/Utilities/System Information.app",
    "Screen Sharing": "/System/Applications/Utilities/Screen Sharing.app",
    "Bluetooth File Exchange": "/System/Applications/Utilities/Bluetooth File Exchange.app",
}

OUTPUT_DIR = Path(__file__).parent.parent / "dictionaries"


def get_sdef_xml(app_path):
    """Extract sdef XML from an app bundle."""
    try:
        result = subprocess.run(
            ["sdef", app_path],
            capture_output=True, text=True, timeout=10
        )
        if result.returncode == 0 and result.stdout.strip():
            return result.stdout
    except (subprocess.TimeoutExpired, FileNotFoundError):
        pass
    return None


def parse_sdef(xml_text):
    """Parse sdef XML into structured data."""
    root = ET.fromstring(xml_text)

    suites = []
    all_commands = []
    all_classes = []
    all_enums = []
    data_types_in = set()
    data_types_out = set()

    for suite in root.findall('.//suite'):
        suite_name = suite.get('name', 'Unknown')
        suite_desc = suite.get('description', '')
        suite_data = {
            'name': suite_name,
            'description': suite_desc,
            'commands': [],
            'classes': [],
            'enumerations': [],
        }

        # Commands
        for cmd in suite.findall('command'):
            cmd_data = {
                'name': cmd.get('name', ''),
                'description': cmd.get('description', ''),
                'code': cmd.get('code', ''),
                'parameters': [],
                'result': None,
                'direct_parameter': None,
            }

            dp = cmd.find('direct-parameter')
            if dp is not None:
                cmd_data['direct_parameter'] = {
                    'type': dp.get('type', 'specifier'),
                    'description': dp.get('description', ''),
                    'optional': dp.get('optional', 'no') == 'yes',
                }
                data_types_in.add(dp.get('type', 'specifier'))

            for param in cmd.findall('parameter'):
                p = {
                    'name': param.get('name', ''),
                    'type': param.get('type', 'specifier'),
                    'description': param.get('description', ''),
                    'optional': param.get('optional', 'no') == 'yes',
                    'code': param.get('code', ''),
                }
                cmd_data['parameters'].append(p)
                data_types_in.add(p['type'])

            res = cmd.find('result')
            if res is not None:
                cmd_data['result'] = {
                    'type': res.get('type', 'specifier'),
                    'description': res.get('description', ''),
                }
                data_types_out.add(res.get('type', 'specifier'))

            suite_data['commands'].append(cmd_data)
            all_commands.append(cmd_data)

        # Classes
        for cls in suite.findall('class'):
            if cls.get('hidden') == 'yes':
                continue
            cls_data = {
                'name': cls.get('name', ''),
                'description': cls.get('description', ''),
                'code': cls.get('code', ''),
                'properties': [],
                'elements': [],
                'inherits': cls.get('inherits', ''),
            }

            for prop in cls.findall('property'):
                if prop.get('hidden') == 'yes':
                    continue
                cls_data['properties'].append({
                    'name': prop.get('name', ''),
                    'type': prop.get('type', ''),
                    'access': prop.get('access', 'rw'),
                    'description': prop.get('description', ''),
                })

            for elem in cls.findall('element'):
                cls_data['elements'].append({
                    'type': elem.get('type', ''),
                })

            # responds-to
            for rt in cls.findall('responds-to'):
                pass  # Could capture if needed

            suite_data['classes'].append(cls_data)
            all_classes.append(cls_data)

        # Enumerations
        for enum in suite.findall('enumeration'):
            enum_data = {
                'name': enum.get('name', ''),
                'code': enum.get('code', ''),
                'enumerators': [],
            }
            for enr in enum.findall('enumerator'):
                enum_data['enumerators'].append({
                    'name': enr.get('name', ''),
                    'description': enr.get('description', ''),
                    'code': enr.get('code', ''),
                })
            suite_data['enumerations'].append(enum_data)
            all_enums.append(enum_data)

        suites.append(suite_data)

    return {
        'suites': suites,
        'all_commands': all_commands,
        'all_classes': all_classes,
        'all_enumerations': all_enums,
        'data_types_in': sorted(data_types_in),
        'data_types_out': sorted(data_types_out),
    }


def generate_yaml(app_name, parsed):
    """Generate YAML knowledge file."""
    lines = []
    slug = app_name.lower().replace(' ', '-')

    lines.append(f"# {app_name} Scripting Dictionary")
    lines.append(f"# Extracted via: sdef | sdef-extract.py")
    lines.append(f"# Usage: tell application \"{app_name}\" to <command>")
    lines.append("")
    lines.append(f"app: \"{app_name}\"")
    lines.append(f"slug: \"{slug}\"")
    lines.append(f"commands_count: {len(parsed['all_commands'])}")
    lines.append(f"classes_count: {len(parsed['all_classes'])}")
    lines.append(f"suites_count: {len(parsed['suites'])}")
    lines.append("")
    lines.append("data_types:")
    lines.append("  accepts:")
    for dt in parsed['data_types_in']:
        lines.append(f"    - \"{dt}\"")
    lines.append("  produces:")
    for dt in parsed['data_types_out']:
        lines.append(f"    - \"{dt}\"")
    lines.append("")

    lines.append("suites:")
    for suite in parsed['suites']:
        lines.append(f"  - name: \"{suite['name']}\"")
        lines.append(f"    description: \"{suite['description']}\"")

        if suite['commands']:
            lines.append("    commands:")
            for cmd in suite['commands']:
                lines.append(f"      - name: \"{cmd['name']}\"")
                lines.append(f"        description: \"{cmd['description']}\"")
                if cmd['direct_parameter']:
                    dp = cmd['direct_parameter']
                    lines.append(f"        direct_parameter:")
                    lines.append(f"          type: \"{dp['type']}\"")
                    lines.append(f"          optional: {str(dp['optional']).lower()}")
                if cmd['parameters']:
                    lines.append(f"        parameters:")
                    for p in cmd['parameters']:
                        lines.append(f"          - name: \"{p['name']}\"")
                        lines.append(f"            type: \"{p['type']}\"")
                        lines.append(f"            optional: {str(p['optional']).lower()}")
                if cmd['result']:
                    lines.append(f"        result:")
                    lines.append(f"          type: \"{cmd['result']['type']}\"")

        if suite['classes']:
            lines.append("    classes:")
            for cls in suite['classes']:
                lines.append(f"      - name: \"{cls['name']}\"")
                lines.append(f"        description: \"{cls['description']}\"")
                if cls['inherits']:
                    lines.append(f"        inherits: \"{cls['inherits']}\"")
                if cls['properties']:
                    lines.append(f"        properties:")
                    for prop in cls['properties']:
                        lines.append(f"          - name: \"{prop['name']}\"")
                        lines.append(f"            type: \"{prop['type']}\"")
                        lines.append(f"            access: \"{prop['access']}\"")
                if cls['elements']:
                    lines.append(f"        elements:")
                    for elem in cls['elements']:
                        lines.append(f"          - \"{elem['type']}\"")

    return '\n'.join(lines)


def generate_markdown(app_name, parsed):
    """Generate human-readable markdown reference."""
    lines = []

    lines.append(f"# {app_name} — AppleScript Reference")
    lines.append("")
    lines.append(f"> Extracted from scripting dictionary via `sdef`")
    lines.append(f"> {len(parsed['all_commands'])} commands, {len(parsed['all_classes'])} classes, {len(parsed['suites'])} suites")
    lines.append("")
    lines.append("```applescript")
    lines.append(f'tell application "{app_name}"')
    lines.append(f"    -- commands go here")
    lines.append(f"end tell")
    lines.append("```")
    lines.append("")

    for suite in parsed['suites']:
        lines.append(f"## {suite['name']}")
        if suite['description']:
            lines.append(f"\n> {suite['description']}\n")

        if suite['commands']:
            lines.append("### Commands\n")
            for cmd in suite['commands']:
                lines.append(f"#### `{cmd['name']}`")
                if cmd['description']:
                    lines.append(f"\n{cmd['description']}\n")

                if cmd['direct_parameter']:
                    dp = cmd['direct_parameter']
                    opt = " *(optional)*" if dp['optional'] else ""
                    lines.append(f"- **Direct parameter**: `{dp['type']}`{opt} — {dp['description']}")

                for p in cmd['parameters']:
                    opt = " *(optional)*" if p['optional'] else ""
                    lines.append(f"- **{p['name']}**: `{p['type']}`{opt} — {p['description']}")

                if cmd['result']:
                    lines.append(f"- **Returns**: `{cmd['result']['type']}` — {cmd['result']['description']}")

                lines.append("")

        if suite['classes']:
            lines.append("### Classes\n")
            for cls in suite['classes']:
                lines.append(f"#### `{cls['name']}`")
                if cls['description']:
                    lines.append(f"\n{cls['description']}\n")
                if cls['inherits']:
                    lines.append(f"*Inherits from: `{cls['inherits']}`*\n")

                if cls['properties']:
                    lines.append("| Property | Type | Access | Description |")
                    lines.append("|----------|------|--------|-------------|")
                    for prop in cls['properties']:
                        lines.append(f"| `{prop['name']}` | `{prop['type']}` | {prop['access']} | {prop['description']} |")
                    lines.append("")

                if cls['elements']:
                    elems = ', '.join(f"`{e['type']}`" for e in cls['elements'])
                    lines.append(f"**Contains**: {elems}\n")

        if suite['enumerations']:
            lines.append("### Enumerations\n")
            for enum in suite['enumerations']:
                lines.append(f"#### `{enum['name']}`\n")
                for enr in enum['enumerators']:
                    desc = f" — {enr['description']}" if enr['description'] else ""
                    lines.append(f"- `{enr['name']}`{desc}")
                lines.append("")

    return '\n'.join(lines)


def generate_examples(app_name, parsed):
    """Generate example AppleScripts for each major command."""
    lines = []
    lines.append(f"# {app_name} — AppleScript Examples")
    lines.append("")
    lines.append(f"> Ready-to-use AppleScript snippets for {app_name}")
    lines.append(f"> Copy any snippet and run with: `osascript -e '<snippet>'`")
    lines.append("")

    # Basic activation
    lines.append("## Basics\n")
    lines.append("```applescript")
    lines.append(f"-- Activate {app_name}")
    lines.append(f'tell application "{app_name}" to activate')
    lines.append("```\n")

    lines.append("```applescript")
    lines.append(f"-- Check if {app_name} is running")
    lines.append(f'if application "{app_name}" is running then')
    lines.append(f'    tell application "{app_name}" to activate')
    lines.append(f"end if")
    lines.append("```\n")

    # Commands
    for cmd in parsed['all_commands']:
        if cmd['name'] in ('open', 'print', 'quit', 'activate', 'close', 'count',
                           'delete', 'duplicate', 'exists', 'make', 'move', 'select',
                           'save', 'get', 'set'):
            lines.append(f"## `{cmd['name']}`\n")
            if cmd['description']:
                lines.append(f"> {cmd['description']}\n")
            lines.append("```applescript")
            lines.append(f'tell application "{app_name}"')

            # Generate contextual example based on command
            if cmd['name'] == 'count':
                lines.append(f"    -- Count items")
                lines.append(f"    set itemCount to count of every window")
                lines.append(f"    return itemCount")
            elif cmd['name'] == 'make':
                lines.append(f"    -- Create new item")
                lines.append(f"    make new document")
            elif cmd['name'] == 'get':
                lines.append(f"    -- Get a property")
                lines.append(f"    get name of front window")
            elif cmd['name'] == 'close':
                lines.append(f"    close front window")
            elif cmd['name'] == 'save':
                lines.append(f"    save front document")
            elif cmd['name'] == 'delete':
                lines.append(f"    -- Delete an item")
                lines.append(f"    -- delete <specifier>")
            else:
                lines.append(f"    {cmd['name']}")

            lines.append(f"end tell")
            lines.append("```\n")

    return '\n'.join(lines)


def generate_index(all_apps_data):
    """Generate master index with data type chaining info (the Automator patent vision)."""
    lines = []
    lines.append("# Apple App Automation Index")
    lines.append("# Maps data types across apps for workflow chaining")
    lines.append("# Inspired by US 7,428,535 — Automatic Relevance Filtering (Sal Soghoian)")
    lines.append("")
    lines.append("# To chain App A → App B, find matching types:")
    lines.append("#   App A produces type X → App B accepts type X → compatible chain")
    lines.append("")
    lines.append("apps:")

    for app_name, data in sorted(all_apps_data.items()):
        slug = app_name.lower().replace(' ', '-')
        lines.append(f"  {slug}:")
        lines.append(f"    name: \"{app_name}\"")
        lines.append(f"    commands: {data['commands_count']}")
        lines.append(f"    classes: {data['classes_count']}")
        lines.append(f"    accepts: {json.dumps(data['types_in'])}")
        lines.append(f"    produces: {json.dumps(data['types_out'])}")

    # Build chaining map
    lines.append("")
    lines.append("# ─── Data Type Chaining Map ───")
    lines.append("# Which apps can pass data to which other apps?")
    lines.append("chains:")

    # Collect all type relationships
    producers = {}  # type -> [apps that produce it]
    consumers = {}  # type -> [apps that consume it]

    for app_name, data in all_apps_data.items():
        slug = app_name.lower().replace(' ', '-')
        for t in data['types_out']:
            producers.setdefault(t, []).append(slug)
        for t in data['types_in']:
            consumers.setdefault(t, []).append(slug)

    # Find chains
    for dtype in sorted(set(producers.keys()) & set(consumers.keys())):
        if dtype in ('specifier', 'type', 'record', 'boolean', 'integer', 'text', 'real', 'list'):
            continue  # Skip generic types
        prods = producers[dtype]
        cons = consumers[dtype]
        if len(prods) > 0 and len(cons) > 0:
            lines.append(f"  - type: \"{dtype}\"")
            lines.append(f"    from: {json.dumps(prods)}")
            lines.append(f"    to: {json.dumps(cons)}")

    return '\n'.join(lines)


def extract_app(app_name, app_path, output_dir):
    """Extract one app's scripting dictionary."""
    slug = app_name.lower().replace(' ', '-')
    app_dir = output_dir / slug
    app_dir.mkdir(parents=True, exist_ok=True)

    print(f"  Extracting: {app_name}...", end=" ", flush=True)

    xml_text = get_sdef_xml(app_path)
    if not xml_text:
        print("SKIP (no sdef)")
        return None

    # Save raw sdef
    (app_dir / f"{slug}.sdef.xml").write_text(xml_text)

    # Parse
    try:
        parsed = parse_sdef(xml_text)
    except ET.ParseError as e:
        print(f"PARSE ERROR: {e}")
        return None

    # Generate files
    yaml_content = generate_yaml(app_name, parsed)
    md_content = generate_markdown(app_name, parsed)
    examples_content = generate_examples(app_name, parsed)

    (app_dir / f"{slug}.yaml").write_text(yaml_content)
    (app_dir / f"{slug}.md").write_text(md_content)
    (app_dir / f"{slug}-examples.md").write_text(examples_content)

    cmd_count = len(parsed['all_commands'])
    cls_count = len(parsed['all_classes'])
    print(f"OK ({cmd_count} commands, {cls_count} classes)")

    return {
        'commands_count': cmd_count,
        'classes_count': cls_count,
        'types_in': parsed['data_types_in'],
        'types_out': parsed['data_types_out'],
    }


def main():
    args = sys.argv[1:]

    if '--list' in args:
        print("Scriptable Apple Apps:")
        for name, path in sorted(APP_PATHS.items()):
            exists = os.path.exists(path)
            status = "OK" if exists else "NOT INSTALLED"
            print(f"  {name:30s} {status}")
        return

    # Filter to specific apps if requested
    if args:
        apps = {name: APP_PATHS[name] for name in args if name in APP_PATHS}
        if not apps:
            print(f"Unknown app(s): {args}")
            print(f"Available: {', '.join(sorted(APP_PATHS.keys()))}")
            sys.exit(1)
    else:
        apps = APP_PATHS

    output_dir = OUTPUT_DIR
    output_dir.mkdir(parents=True, exist_ok=True)

    print(f"═══ Apple Scripting Dictionary Extractor ═══")
    print(f"Output: {output_dir}")
    print(f"Apps: {len(apps)}")
    print()

    all_data = {}

    for app_name, app_path in sorted(apps.items()):
        if not os.path.exists(app_path):
            print(f"  {app_name}: NOT INSTALLED, skipping")
            continue

        result = extract_app(app_name, app_path, output_dir)
        if result:
            all_data[app_name] = result

    # Generate master index
    if all_data:
        index_content = generate_index(all_data)
        (output_dir / "_index.yaml").write_text(index_content)
        print(f"\nMaster index: {output_dir / '_index.yaml'}")

    print(f"\n═══ Done: {len(all_data)} apps extracted ═══")
    print(f"Each app has: .yaml (machine), .md (human), -examples.md (snippets)")
    print(f"Chain workflows using _index.yaml data type map")


if __name__ == '__main__':
    main()
