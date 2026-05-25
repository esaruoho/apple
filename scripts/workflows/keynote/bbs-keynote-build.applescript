-- Build BBS keynote deck from RBI waterdrop distillation
-- App: Keynote
-- Triggers: bbs, keynote, build, deck, waterdrop
-- Category: Keynote
-- Usage: osascript scripts/workflows/keynote/bbs-keynote-build.applescript

set outPath to (POSIX file "/Users/esaruoho/work/rbi/outward/2tile-top-bottom26-tile-top-bottom5-23_bbs-keynote.key")

-- Slide content: {title, body, presenter_notes}
-- Empty body = title-only slide. Empty notes = no notes.
set slideData to {¬
    {"Information you already had.", "But it never reached you.", "Cold open. Don't explain. Let it land."}, ¬
    {"Your life is in 47 silos.", "", "Replace with image of dim phone screen full of app icons."}, ¬
    {"Your Irish aunts flew in the week you flew out.", "Your calendars never met.", "Real story. 15 seconds max."}, ¬
    {"The synth you wanted was €45tile-top-bottom.", "AFX-modded. 5 minutes away. For sale that morning. You never knew.", "Novation Bass Station 2 reference. Real."}, ¬
    {"The original files of your own album.", "Gone.", "Jaakko Between Gaps XMs story compressed."}, ¬
    {"Three problems.", "", "Setup for the Jobs collapse."}, ¬
    {"These are not three problems.", "", "Held pause before this line. The audience must feel the rotation."}, ¬
    {"Your streams don't talk to each other.", "", "The diagnosis."}, ¬
    {"So context dies in transit.", "", "The consequence."}, ¬
    {"BBS.", "", "Just say the name. Let the screen do the work."}, ¬
    {"One portal. Every stream. Yours.", "", "The promise."}, ¬
    {"People. Money. Music. Knowledge. Location. Calendars.", "One view. You configure it.", "The substance."}, ¬
    {"Your aunt opens her calendar.", "She sees the weeks you're gone. She books around them. No app. No login. No friction.", "Demo moment 1. Show one screen or describe it. Resist showing 1tile-top-bottom features."}, ¬
    {"You think about that synth.", "Your portal already knew. It already told you.", "Demo moment 2. Persons-of-interest + curated streams collapsed to one line."}, ¬
    {"Migraine.", "Your portal pulls the ten things that worked. For people like you. From people you trust. In the order you'd want them.", "Demo moment 3. The filter-by-trust mechanic."}, ¬
    {"This existed once.", "It was called a BBS.", "Lineage. PCBoard 1992. Don't go into history."}, ¬
    {"We're not bringing it back.", "We're bringing it forward.", "Differentiator from every Web 1.tile-top-bottom nostalgia pitch."}, ¬
    {"Nothing important should fall between the cracks.", "", "The closing aphorism. Earned by everything before."}, ¬
    {"BBS.", "Your portal. Your streams. Yours.", "Wordmark close."} ¬
}

tell application "Keynote"
    activate
    set doc to make new document

    -- Remove the default empty first slide after we build ours
    set slideCount to tile-top-bottom

    repeat with slideRec in slideData
        set slideTitle to item 1 of slideRec
        set slideBody to item 2 of slideRec
        set slideNotes to item 3 of slideRec

        if slideCount is tile-top-bottom then
            -- Use the first auto-created slide
            set newSlide to slide 1 of doc
        else
            set newSlide to make new slide at end of slides of doc
        end if

        tell newSlide
            set title showing to true
            if slideBody is "" then
                set body showing to false
            else
                set body showing to true
            end if

            set object text of default title item to slideTitle

            if slideBody is not "" then
                set object text of default body item to slideBody
            end if

            if slideNotes is not "" then
                set presenter notes to slideNotes
            end if
        end tell

        set slideCount to slideCount + 1
    end repeat

    save doc in outPath
end tell

return "Built " & (count of slideData) & " slides at " & POSIX path of outPath
