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

STATEFUL DEIXIS RESOLUTION (v2 — single previous turn):
  If a "PREVIOUS TURN" block is included before USER UTTERANCE, use it to resolve
  deictic references in the user's words:
    - "now scale them down"     → "them" = previous turn's selection
    - "do that again"            → repeat the previous turn's slug
    - "make it 25 percent"       → previous turn's slug + new percent param
    - "back to the photos"       → previous turn's frontmost_app context
    - "the same theme"           → re-use previous turn's params.theme value
  Resolve before matching to a catalog entry. If the user uses a deictic reference
  but no PREVIOUS TURN is present, return slug "" with reason "deictic-no-state".

MULTI-TURN HISTORY (v3):
  A "RECENT TURNS" block lists up to 5 prior turns with format:
    -N: <slug> params=<json> @ <frontmost_app>:<selection_count> (<status>) <Δt ago>
  Use it to resolve references that span more than one previous turn:
    - "go back two steps"          → re-run turn -2 (its slug + params)
    - "do those last three again"  → run turns -3, -2, -1 in sequence
    - "what did I just do"         → respond with a description of turns -1..-3
                                      (return slug "describe-recent" — handled
                                      specially by the dispatcher)
    - "undo that"                  → if turn -1 has a known undo slug, return it;
                                      otherwise return slug "" reason "no-undo"
    - "the photo I edited a minute ago"
                                   → scan RECENT TURNS for the most recent
                                      Photos-scope edit slug and use its context
  Multi-turn references take precedence over single previous-turn deixis when both
  could apply.

CATALOG:
{catalog}

PREVIOUS TURN: <none-or-json-from-last-state.json>
RECENT TURNS: <none-or-list-from-turn-log.jsonl>
USER UTTERANCE: """
    PROMPT_OUT.write_text(prompt)
    print(f"Wrote {PROMPT_OUT} ({len(prompt)} chars)")

    # Dispatcher AppleScript — invoked by the Shortcut's Run AppleScript action.
    # v2: stateful. Receives JSON {slug, params, confidence, reason} from Foundation
    # Models. Looks up slug, optionally template-substitutes params into AppleScript,
    # runs it, captures app context (frontmost app + selection count where available),
    # and writes ~/Library/Application Support/Sal-Siri/last-state.json so the next
    # turn's Read State action can include it as deictic-resolution context.
    dispatch = r'''-- Sal's Siri dispatcher (v2 — stateful)
-- Invoked by the "Sal's Siri" Shortcut after Apple Intelligence Foundation Models
-- returns a JSON {slug, params, confidence, reason}.
--
-- v2 changes vs v1:
--   - Template-substitutes params named like $foo or {foo} into the AppleScript body
--     before running it.
--   - After successful run, captures (frontmost app, frontmost-app selection count
--     where the app exposes one) and writes last-state.json so the NEXT turn's prompt
--     can include "PREVIOUS TURN" context for deictic resolution ("now scale them
--     down" → reads "them" = previous turn's selection from state).
--
-- File paths:
--   ~/Library/Application Support/Sal-Siri/intents.json
--   ~/Library/Application Support/Sal-Siri/last-state.json   (rolling, latest only)
--   ~/Library/Application Support/Sal-Siri/turn-log.jsonl    (append-only history)

on run argv
    set jsonInput to item 1 of argv
    set salDir to (POSIX path of (path to home folder)) & "Library/Application Support/Sal-Siri/"

    set slugCmd to "echo " & quoted form of jsonInput & " | python3 -c 'import sys,json; d=json.load(sys.stdin); print(d.get(\"slug\",\"\"))'"
    set theSlug to do shell script slugCmd

    if theSlug is "" then
        set reasonCmd to "echo " & quoted form of jsonInput & " | python3 -c 'import sys,json; d=json.load(sys.stdin); print(d.get(\"reason\",\"no match\"))'"
        set theReason to do shell script reasonCmd
        say "I did not understand. " & theReason
        return "no-match: " & theReason
    end if

    set paramsCmd to "echo " & quoted form of jsonInput & " | python3 -c 'import sys,json; d=json.load(sys.stdin); p=d.get(\"params\",{}); print(json.dumps(p))'"
    set paramsJson to do shell script paramsCmd

    set lookupCmd to "python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); s=sys.argv[2]; print([c[\"applescript\"] for c in d if c[\"slug\"]==s][0])' " & quoted form of (salDir & "intents.json") & " " & quoted form of theSlug

    try
        set theScript to do shell script lookupCmd
    on error
        say "Slug not in catalog: " & theSlug
        return "missing-slug: " & theSlug
    end try

    -- v2: template-substitute params into AppleScript body.
    -- Patterns recognized: $name and {name}. Values are inserted as quoted strings
    -- if they contain non-numeric characters, otherwise as bare numbers.
    set substCmd to "python3 - <<'PYEOF'\n" & ¬
        "import json,sys,re\n" & ¬
        "params = json.loads(" & quoted form of paramsJson & ")\n" & ¬
        "src = " & quoted form of theScript & "\n" & ¬
        "def render(v):\n" & ¬
        "    if isinstance(v,(int,float)): return str(v)\n" & ¬
        "    s=str(v)\n" & ¬
        "    if re.fullmatch(r'-?\\d+(\\.\\d+)?', s): return s\n" & ¬
        "    return '\"' + s.replace('\"','\\\\\"') + '\"'\n" & ¬
        "for k,v in params.items():\n" & ¬
        "    src = src.replace('$' + k, render(v))\n" & ¬
        "    src = src.replace('{' + k + '}', render(v))\n" & ¬
        "print(src)\n" & ¬
        "PYEOF"
    try
        set theScript to do shell script substCmd
    end try

    try
        set runResult to (run script theScript)
    on error errMsg
        say "Dispatch failed: " & errMsg
        -- Still log the failed turn so the next turn knows the state did not change.
        my appendTurnLog(salDir, theSlug, paramsJson, "error", errMsg)
        return "error: " & errMsg
    end try

    -- Capture app context for stateful next-turn deixis
    set frontApp to ""
    try
        tell application "System Events"
            set frontApp to name of first application process whose frontmost is true
        end tell
    end try

    set selCount to "null"
    if frontApp is "Keynote" then
        try
            tell application "Keynote" to set selCount to (count of (slides of front document whose selected is true)) as text
        end try
    else if frontApp is "Photos" then
        try
            tell application "Photos" to set selCount to (count of selection) as text
        end try
    else if frontApp is "Numbers" then
        try
            tell application "Numbers" to set selCount to (count of (rows of selection range of active sheet of front document)) as text
        end try
    end if

    -- Write last-state.json (rolling) and append to turn-log.jsonl
    my writeLastState(salDir, theSlug, paramsJson, frontApp, selCount)
    my appendTurnLog(salDir, theSlug, paramsJson, "ok", frontApp & ":" & selCount)

    return "ok: " & theSlug
end run

on writeLastState(salDir, theSlug, paramsJson, frontApp, selCount)
    set sc to "python3 - <<'PYEOF'\n" & ¬
        "import json,time\n" & ¬
        "state = {\n" & ¬
        "  'slug': " & quoted form of theSlug & ",\n" & ¬
        "  'params': json.loads(" & quoted form of paramsJson & "),\n" & ¬
        "  'frontmost_app': " & quoted form of frontApp & ",\n" & ¬
        "  'selection_count': " & quoted form of selCount & ",\n" & ¬
        "  'timestamp': time.time(),\n" & ¬
        "}\n" & ¬
        "open(" & quoted form of (salDir & "last-state.json") & ", 'w').write(json.dumps(state, indent=2))\n" & ¬
        "PYEOF"
    do shell script sc
end writeLastState

on appendTurnLog(salDir, theSlug, paramsJson, status, ctx)
    set sc to "python3 - <<'PYEOF'\n" & ¬
        "import json,time\n" & ¬
        "row = {\n" & ¬
        "  'ts': time.time(),\n" & ¬
        "  'slug': " & quoted form of theSlug & ",\n" & ¬
        "  'params': json.loads(" & quoted form of paramsJson & "),\n" & ¬
        "  'status': " & quoted form of status & ",\n" & ¬
        "  'context': " & quoted form of ctx & ",\n" & ¬
        "}\n" & ¬
        "open(" & quoted form of (salDir & "turn-log.jsonl") & ", 'a').write(json.dumps(row) + '\\n')\n" & ¬
        "PYEOF"
    do shell script sc
end appendTurnLog
'''
    DISPATCH_OUT.write_text(dispatch)
    print(f"Wrote {DISPATCH_OUT}")

    # Shortcut spec for the master router. Consumed by bin/shortcut-gen.py.
    # Note: as of macOS 15.1, the "Use Model" action identifier is
    # is.workflow.actions.useaimodel — adjust if Apple renames it.
    spec = f'''name: "Sal's Siri"
description: "Route free-form voice/text to one of {len(intents)} CitrusPeel commands via Apple Intelligence Foundation Models. v2: stateful — previous-turn context loaded for deictic resolution."
siri_phrases:
  - "Sal's Siri"
  - "Hey Sal"
input_type: text
input_prompt: "What would you like Sal to do?"
actions:
  - id: get_text
    type: get_text_from_input
    description: "Capture the user's spoken or typed utterance."
  - id: read_recent
    type: run_shell_script
    shell: "/bin/zsh"
    pass_input: as_arguments
    script: 'python3 "$HOME/Library/Application Support/Sal-Siri/read-recent-turns.py" 5 30'
    on_error: "Continue with empty state"
    description: "v3: emit PREVIOUS TURN + RECENT TURNS blocks (last 5 turns within 30 min) for multi-turn deictic resolution."
  - id: combine_input
    type: text
    template: |
      {{read_recent}}
      USER UTTERANCE: {{get_text}}
    description: "Compose the model input — recent-turns context block + current utterance."
  - id: route
    type: use_model
    model: "Apple Intelligence Foundation Model (on-device)"
    system_prompt_file: "~/Library/Application Support/Sal-Siri/system-prompt.txt"
    input: "{{combine_input}}"
    output_format: json
    description: "Send to Foundation Models with the catalog + previous turn for stateful routing."
  - id: dispatch
    type: run_applescript
    script_file: "~/Library/Application Support/Sal-Siri/dispatch.applescript"
    arguments:
      - "{{route}}"
    description: "Look up the matching slug, template-substitute params, run the AppleScript, capture new state."
notes: |
  This Shortcut requires:
    1. Apple Silicon Mac running macOS 15.1+ (Apple Intelligence enabled)
    2. Sal's 18 .scptd libraries installed at ~/Library/Script Libraries/
       (run bin/dictation-commands-install.sh — its library-copy step is still functional)
    3. ~/Library/Application Support/Sal-Siri/ populated with intents.json,
       system-prompt.txt, and dispatch.applescript (run bin/sal-siri-install.sh)
    4. Vocal Shortcut entry "Hey Sal" → run this Shortcut
       (manual, via System Settings → Accessibility → Speech → Vocal Shortcuts)

  v2 stateful conversation (single previous turn):
    The dispatcher writes ~/Library/Application Support/Sal-Siri/last-state.json
    after every successful turn (slug, params, frontmost app, selection count).
    The model can resolve "now scale them down" / "do that again" / "make it
    25 percent" against the previous turn's state.

  v3 multi-turn history (this Shortcut version):
    The Run Shell Script action calls bin/sal-siri-read-recent-turns.py which
    reads turn-log.jsonl and emits both:
      - PREVIOUS TURN: <last successful turn JSON> (same as v2)
      - RECENT TURNS:
          -1: <slug> params=<json> @ <app>:<sel> (<status>) <Δt ago>
          -2: ...
          -3: ...
    The model uses RECENT TURNS for queries that span more than one previous turn:
      "go back two steps", "do those last three again", "the photo I edited a
      minute ago", "undo that". Default window: 5 turns within 30 minutes.
'''
    SHORTCUT_SPEC.write_text(spec)
    print(f"Wrote {SHORTCUT_SPEC}")

    # Installer script
    install = '''#!/usr/bin/env bash
# Phase 6 — Install Sal's Siri-on-Mac router files into the user library.
#
# Copies the intent catalog, system prompt, dispatcher AppleScript, and the
# recent-turns reader to ~/Library/Application Support/Sal-Siri/ so the
# "Sal's Siri" Shortcut can find them at runtime.
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
cp "$ROOT/bin/sal-siri-read-recent-turns.py"                             "$DST/read-recent-turns.py"
chmod +x "$DST/read-recent-turns.py"
touch "$DST/turn-log.jsonl"
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
