-- Sal's Siri dispatcher (v2 — stateful)
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
