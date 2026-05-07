#!/usr/bin/env python3
"""
Phase 6 — Sal's Siri-on-Mac router rebuild.

Generates the components for a 2026 functional equivalent of Sal's killed
Siri-on-Mac prototype: a single Shortcut named "Sal's Siri" that routes free-form
voice/text through Apple Intelligence Foundation Models (macOS 15.1+) to one of
the 596 deterministic CitrusPeel commands, with slot-filling.

Architecture (theorized in analysis/sal/sal-siri-on-mac-theory.md):

    User speaks "Hey Sal, give me a wide gradient presentation"
        ↓
    Vocal Shortcut "Hey Sal" → runs "Sal's Siri" Shortcut
        ↓
    Sal's Siri Shortcut:
        1. takes the rest of the utterance as text input
        2. calls Foundation Models with the system prompt + catalog
        3. receives JSON {slug, params}
        4. Run AppleScript dispatches to ~/Library/Application Support/Sal-Siri/dispatch.applescript
            which looks up the slug in the intent catalog and runs the corresponding
            tell script "DC-XXX" to handler(params) AppleScript
        ↓
    Result: Keynote opens a new wide presentation with the gradient theme,
    just like CitrusPeel's deterministic "make a new wide presentation using
    the gradient template" — but slot-filled naturally.

Deliverables:
    1. scripts/sal/dictation-commands/sal-siri-intents.json
       — intent catalog: 596 entries, each with slug, title, primary phrase, all phrases,
         scope, applescript body. This is what gets installed to
         ~/Library/Application Support/Sal-Siri/intents.json at deploy time.
    2. scripts/sal/dictation-commands/sal-siri-system-prompt.txt
       — the LLM system prompt that turns the catalog into a routing function
    3. scripts/sal/dictation-commands/sal-siri-dispatch.applescript
       — the dispatcher AppleScript that the Shortcut's Run AppleScript action invokes
    4. scripts/sal/dictation-commands/sal-siri-shortcut-spec.yaml
       — the Shortcut spec for the master router, consumable by bin/shortcut-gen.py
    5. bin/sal-siri-install.sh
       — installer that places intents.json + dispatch.applescript in
         ~/Library/Application Support/Sal-Siri/ so the Shortcut can find them
"""
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CMD_JSON = ROOT / "scripts/sal/dictation-commands/commands.json"
DC_DIR = ROOT / "scripts/sal/dictation-commands"
INTENTS_OUT = DC_DIR / "sal-siri-intents.json"
PROMPT_OUT = DC_DIR / "sal-siri-system-prompt.txt"
DISPATCH_OUT = DC_DIR / "sal-siri-dispatch.applescript"
SHORTCUT_SPEC = DC_DIR / "sal-siri-shortcut-spec.yaml"
INSTALL_SCRIPT = ROOT / "bin/sal-siri-install.sh"

def slugify(s):
    s = re.sub(r"[^a-zA-Z0-9]+", "-", s).strip("-").lower()
    return s[:80]

def main():
    cmds = json.load(open(CMD_JSON))
    intents = []
    seen_slugs = set()
    for c in cmds:
        if not c.get("phrases"):
            continue
        primary = c["phrases"][0]
        slug = slugify(c.get("script_file", primary).replace(".scpt", ""))
        if not slug or slug in seen_slugs:
            continue
        seen_slugs.add(slug)
        applescript = c["script_text"]
        lib_match = re.search(r'tell script "([^"]+)"', applescript)
        if lib_match and "use script" not in applescript:
            applescript = f'use script "{lib_match.group(1)}"\n{applescript}'
        intents.append({
            "slug": slug,
            "title": c.get("title") or primary.title(),
            "primary_phrase": primary,
            "phrases": c["phrases"],
            "scope": c.get("scope", "*"),
            "description": c.get("description", ""),
            "source_library": c.get("script_dir", ""),
            "applescript": applescript,
        })
    INTENTS_OUT.write_text(json.dumps(intents, indent=2))
    print(f"Wrote {INTENTS_OUT} ({len(intents)} intents)")

    # System prompt — concise routing instructions + condensed catalog
    # Include only slug + primary phrase + scope to keep tokens manageable.
    catalog_lines = []
    for i in intents:
        catalog_lines.append(f'  {i["slug"]}: "{i["primary_phrase"]}" (scope={i["scope"]})')
    catalog = "\n".join(catalog_lines)
    prompt = f"""You are Sal's Siri-on-Mac router. Your job is to map a single user utterance to ONE of the {len(intents)} commands in the catalog below, extracting any numeric or text parameters.

Catalog format: slug: "primary phrase" (scope=app)

Rules:
  1. Match the user's intent to the closest catalog entry, even if their phrasing differs from the primary phrase. Sal's commands accept many natural phrasings.
  2. If the user mentions a number, percent, or specific value (e.g. "scale down 25%", "go to slide 7", "the gradient theme"), extract it as a parameter.
  3. If no catalog entry matches, return slug "" and reason explaining why.
  4. Respond ONLY with strict JSON: {{"slug": "<slug-or-empty>", "params": {{<key-value pairs>}}, "confidence": <0.0-1.0>, "reason": "<short>"}}
  5. Do not include any text outside the JSON object.

CATALOG:
{catalog}

USER UTTERANCE: """
    PROMPT_OUT.write_text(prompt)
    print(f"Wrote {PROMPT_OUT} ({len(prompt)} chars)")

    # Dispatcher AppleScript — invoked by the Shortcut's Run AppleScript action.
    # Receives JSON from Foundation Models output, looks up slug, runs the matching
    # AppleScript via run script.
    dispatch = '''-- Sal's Siri dispatcher
-- Invoked by the "Sal's Siri" Shortcut after Apple Intelligence Foundation Models
-- returns a JSON {slug, params, confidence, reason}.
--
-- Reads ~/Library/Application Support/Sal-Siri/intents.json (installed by
-- bin/sal-siri-install.sh) to find the AppleScript body for the matching slug,
-- substitutes any params, and runs it.

on run argv
    set jsonInput to item 1 of argv

    -- Parse the JSON via shell + python3 (AppleScript has no native JSON)
    set slugCmd to "echo " & quoted form of jsonInput & " | python3 -c 'import sys,json; d=json.load(sys.stdin); print(d.get(\\"slug\\",\\"\\"))'"
    set theSlug to do shell script slugCmd

    if theSlug is "" then
        set reasonCmd to "echo " & quoted form of jsonInput & " | python3 -c 'import sys,json; d=json.load(sys.stdin); print(d.get(\\"reason\\",\\"no match\\"))'"
        set theReason to do shell script reasonCmd
        say "I did not understand. " & theReason
        return "no-match: " & theReason
    end if

    -- Look up the AppleScript body for this slug
    set lookupCmd to "python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); s=sys.argv[2]; print([c[\\"applescript\\"] for c in d if c[\\"slug\\"]==s][0])' ~/Library/Application\\\\ Support/Sal-Siri/intents.json " & quoted form of theSlug

    try
        set theScript to do shell script lookupCmd
    on error
        say "Slug not in catalog: " & theSlug
        return "missing-slug: " & theSlug
    end try

    -- Optionally substitute params. v1 ignores params and runs the deterministic
    -- AppleScript verbatim. v2 will template-substitute $param names.
    try
        run script theScript
    on error errMsg
        say "Dispatch failed: " & errMsg
        return "error: " & errMsg
    end try
    return "ok: " & theSlug
end run
'''
    DISPATCH_OUT.write_text(dispatch)
    print(f"Wrote {DISPATCH_OUT}")

    # Shortcut spec for the master router. Consumed by bin/shortcut-gen.py.
    # Note: as of macOS 15.1, the "Use Model" action identifier is
    # is.workflow.actions.useaimodel — adjust if Apple renames it.
    spec = f'''name: "Sal's Siri"
description: "Route free-form voice/text to one of {len(intents)} CitrusPeel commands via Apple Intelligence Foundation Models."
siri_phrases:
  - "Sal's Siri"
  - "Hey Sal"
input_type: text
input_prompt: "What would you like Sal to do?"
actions:
  - id: get_text
    type: get_text_from_input
    description: "Capture the user's spoken or typed utterance."
  - id: route
    type: use_model
    model: "Apple Intelligence Foundation Model (on-device)"
    system_prompt_file: "~/Library/Application Support/Sal-Siri/system-prompt.txt"
    input: "{{get_text}}"
    output_format: json
    description: "Send utterance to Foundation Models with the Sal catalog as routing schema."
  - id: dispatch
    type: run_applescript
    script_file: "~/Library/Application Support/Sal-Siri/dispatch.applescript"
    arguments:
      - "{{route}}"
    description: "Look up the matching slug in the catalog and run the corresponding AppleScript."
notes: |
  This Shortcut requires:
    1. Apple Silicon Mac running macOS 15.1+ (Apple Intelligence enabled)
    2. Sal's 18 .scptd libraries installed at ~/Library/Script Libraries/
       (run bin/dictation-commands-install.sh — its library-copy step is still functional)
    3. ~/Library/Application Support/Sal-Siri/ populated with intents.json,
       system-prompt.txt, and dispatch.applescript (run bin/sal-siri-install.sh)
    4. Vocal Shortcut entry "Hey Sal" → run this Shortcut
       (manual, via System Settings → Accessibility → Speech → Vocal Shortcuts)
'''
    SHORTCUT_SPEC.write_text(spec)
    print(f"Wrote {SHORTCUT_SPEC}")

    # Installer script
    install = '''#!/usr/bin/env bash
# Phase 6 — Install Sal's Siri-on-Mac router files into the user library.
#
# Copies the intent catalog, system prompt, and dispatcher AppleScript to
# ~/Library/Application Support/Sal-Siri/ so the "Sal's Siri" Shortcut can find
# them at runtime.
#
# Pre-requisite: bin/dictation-commands-install.sh has been run (the 18 .scptd
# libraries must be in ~/Library/Script Libraries/).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DST="$HOME/Library/Application Support/Sal-Siri"
mkdir -p "$DST"
cp "$ROOT/scripts/sal/dictation-commands/sal-siri-intents.json"          "$DST/intents.json"
cp "$ROOT/scripts/sal/dictation-commands/sal-siri-system-prompt.txt"     "$DST/system-prompt.txt"
cp "$ROOT/scripts/sal/dictation-commands/sal-siri-dispatch.applescript"  "$DST/dispatch.applescript"
echo "Installed Sal's Siri runtime at: $DST"
echo ""
echo "Next steps:"
echo "  1. Import the Shortcut spec at:"
echo "     scripts/sal/dictation-commands/sal-siri-shortcut-spec.yaml"
echo "     into Shortcuts.app (use bin/shortcut-gen.py once it supports use_model action)"
echo "  2. Add a Vocal Shortcut entry: System Settings → Accessibility → Speech →"
echo "     Vocal Shortcuts → + → phrase: \\"Hey Sal\\" → action: Run Shortcut → Sal's Siri"
echo "  3. Test: say \\"Hey Sal\\" then \\"give me a wide gradient presentation\\""
'''
    INSTALL_SCRIPT.write_text(install)
    INSTALL_SCRIPT.chmod(0o755)
    print(f"Wrote {INSTALL_SCRIPT}")

    print("")
    print("Phase 6 generation complete.")
    print(f"  Intents:           {len(intents)}")
    print(f"  System prompt:     {len(prompt)} chars")
    print(f"  Dispatcher:        {DISPATCH_OUT.stat().st_size} bytes")
    print(f"  Shortcut spec:     {SHORTCUT_SPEC}")
    print(f"  Installer:         {INSTALL_SCRIPT}")

if __name__ == "__main__":
    main()
