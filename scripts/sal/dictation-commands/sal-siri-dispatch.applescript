-- Sal's Siri dispatcher
-- Invoked by the "Sal's Siri" Shortcut after Apple Intelligence Foundation Models
-- returns a JSON {slug, params, confidence, reason}.
--
-- Reads ~/Library/Application Support/Sal-Siri/intents.json (installed by
-- bin/sal-siri-install.sh) to find the AppleScript body for the matching slug,
-- substitutes any params, and runs it.

on run argv
    set jsonInput to item 1 of argv

    -- Parse the JSON via shell + python3 (AppleScript has no native JSON)
    set slugCmd to "echo " & quoted form of jsonInput & " | python3 -c 'import sys,json; d=json.load(sys.stdin); print(d.get(\"slug\",\"\"))'"
    set theSlug to do shell script slugCmd

    if theSlug is "" then
        set reasonCmd to "echo " & quoted form of jsonInput & " | python3 -c 'import sys,json; d=json.load(sys.stdin); print(d.get(\"reason\",\"no match\"))'"
        set theReason to do shell script reasonCmd
        say "I did not understand. " & theReason
        return "no-match: " & theReason
    end if

    -- Look up the AppleScript body for this slug
    set lookupCmd to "python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); s=sys.argv[2]; print([c[\"applescript\"] for c in d if c[\"slug\"]==s][0])' ~/Library/Application\\ Support/Sal-Siri/intents.json " & quoted form of theSlug

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
