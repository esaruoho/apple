#!/usr/bin/env python3
"""
Phase 3 Path B — Generate macOS Shortcuts (.shortcut specs) from CitrusPeel command catalog.

Reads scripts/sal/dictation-commands/commands.json (596 commands, 1966 phrasings)
and emits a Shortcut spec per command into shortcuts/sal-dictation/.

Each spec is a YAML file consumed by bin/shortcut-gen.py to produce a signed .shortcut
file with an `is.workflow.actions.runapplescript` action and the Sal-original
`tell script "DC-XXX" to handlerName()` script text.

Output: shortcuts/sal-dictation/*.yaml (one per command)
"""
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CMD_JSON = ROOT / "scripts/sal/dictation-commands/commands.json"
OUT_DIR = ROOT / "scripts/sal/dictation-commands/shortcut-specs"

def slugify(s):
    s = re.sub(r"[^a-zA-Z0-9]+", "-", s).strip("-").lower()
    return s[:80]

def main():
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    cmds = json.load(open(CMD_JSON))
    written = 0
    skipped = 0
    for c in cmds:
        if not c.get("phrases"):
            skipped += 1
            continue
        primary = c["phrases"][0]
        siri_phrases = c["phrases"]
        slug = slugify(c.get("script_file", primary).replace(".scpt", ""))
        if not slug:
            skipped += 1
            continue
        # Wrap Sal's script text in a Shortcuts-friendly block. Sal's script_text is
        # typically a single-line `tell script "DC-XXX" to handlerName()`.
        applescript = c["script_text"]
        # If it references a script library, ensure it loads from the user library.
        if 'tell script "' in applescript and 'use script' not in applescript:
            lib_match = re.search(r'tell script "([^"]+)"', applescript)
            if lib_match:
                lib = lib_match.group(1)
                applescript = f'use script "{lib}"\n{applescript}'

        spec = {
            "name": c.get("title") or primary.title(),
            "siri_phrases": siri_phrases,
            "scope": c.get("scope", "*"),
            "description": c.get("description", ""),
            "source_library": c.get("script_dir", ""),
            "source_file": c.get("script_file", ""),
            "applescript": applescript,
        }
        # Emit minimal YAML by hand (no pyyaml dep)
        lines = []
        lines.append(f'name: {json.dumps(spec["name"])}')
        lines.append(f'scope: {json.dumps(spec["scope"])}')
        lines.append(f'description: {json.dumps(spec["description"])}')
        lines.append(f'source_library: {json.dumps(spec["source_library"])}')
        lines.append(f'source_file: {json.dumps(spec["source_file"])}')
        lines.append("siri_phrases:")
        for p in siri_phrases:
            lines.append(f'  - {json.dumps(p)}')
        lines.append("applescript: |")
        for line in applescript.splitlines():
            lines.append(f"  {line}")
        out_path = OUT_DIR / f"{slug}.yaml"
        out_path.write_text("\n".join(lines) + "\n")
        written += 1
    print(f"Wrote {written} Shortcut specs to {OUT_DIR}")
    print(f"Skipped {skipped} entries with no phrases or no slug")
    print(f"Next: extend bin/shortcut-gen.py to consume these specs and emit signed .shortcut files")

if __name__ == "__main__":
    main()
