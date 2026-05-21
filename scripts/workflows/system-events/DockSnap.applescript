-- DockSnap.applescript
-- Tile windows into an auto-sized non-uniform grid.
--
-- Modes:
--   no args                     → every visible foreground app, one cell per app, main screen
--   <appname>                   → that app's windows tiled in a grid, main screen
--   <appname> <screenIdx>       → tile on a specific screen (0 = main)
--   <appname> all               → distribute windows across ALL screens
--                                 (round-robin: window 1 → screen 0, window 2 → screen 1, …)
--   --list-screens              → print one screen per line: idx<TAB>name<TAB>visible-frame
--
-- The grid is row-based and non-uniform: rows = round(sqrt(n)), each row gets
-- ceil/floor of n/rows cells. n=5 → 3+2, n=7 → 4+3, n=11 → 4+4+3 — every cell
-- filled, no empty slots.
--
-- Apple-native: NSScreen via /usr/bin/swift + System Events.

on run argv
    set targetName to ""
    set screenArg to "0"   -- 0 = main; "all" = distribute across screens

    if (count of argv) ≥ 1 then set targetName to item 1 of argv as text
    if (count of argv) ≥ 2 then set screenArg to item 2 of argv as text

    if targetName is "--list-screens" then
        listScreens()
        return
    end if

    if screenArg is "all" then
        -- Distribute across all screens
        set screenCount to my screenCountInt()
        if targetName is "" then
            do shell script "/usr/bin/osascript -e 'display notification \"--all needs an appname\" with title \"Dock Snap\"'"
            return
        end if
        distributeAcrossScreens(targetName)
        return
    end if

    set screenIdx to screenArg as integer
    set frameStr to my screenFrame(screenIdx)
    set AppleScript's text item delimiters to " "
    set parts to text items of frameStr
    set sx to (item 1 of parts) as integer
    set sy to (item 2 of parts) as integer
    set sw to (item 3 of parts) as integer
    set sh to (item 4 of parts) as integer
    set AppleScript's text item delimiters to ""

    if targetName is "" then
        tileAllApps(sx, sy, sw, sh)
    else
        tileOneApp(targetName, sx, sy, sw, sh)
    end if
end run


-- Return the visible frame of screen N in TOP-LEFT coordinates as "x y w h".
on screenFrame(idx)
    return do shell script "/usr/bin/swift -e 'import AppKit; let scrs = NSScreen.screens; let i = " & idx & "; guard i >= 0 && i < scrs.count else { print(\"0 0 1440 900\"); exit(1) }; let s = scrs[i]; let totalH = scrs.map { $0.frame.origin.y + $0.frame.size.height }.max()!; let f = s.frame; let v = s.visibleFrame; let topY = totalH - (v.origin.y + v.size.height); print(\"\\(Int(v.origin.x)) \\(Int(topY)) \\(Int(v.size.width)) \\(Int(v.size.height))\")'"
end screenFrame


on screenCountInt()
    set s to do shell script "/usr/bin/swift -e 'import AppKit; print(NSScreen.screens.count)'"
    return s as integer
end screenCountInt


on listScreens()
    do shell script "/usr/bin/swift -e 'import AppKit; for (i, s) in NSScreen.screens.enumerated() { let v = s.visibleFrame; print(\"\\(i)\\t\\(s.localizedName)\\t\\(Int(v.origin.x)),\\(Int(v.origin.y)) \\(Int(v.size.width))x\\(Int(v.size.height))\") }'"
end listScreens


-- Non-uniform row layout: rows = round(sqrt(n)), each row gets ceil/floor of n/rows.
on rowLayout(n)
    if n ≤ 1 then return {1}
    if n = 2 then return {2}
    if n = 3 then return {3}
    if n = 4 then return {2, 2}
    set r to round (n ^ 0.5) rounding to nearest
    if r < 1 then set r to 1
    set base to n div r
    set extra to n mod r
    set out to {}
    repeat with i from 1 to r
        if i ≤ extra then
            set end of out to base + 1
        else
            set end of out to base
        end if
    end repeat
    return out
end rowLayout


on snapshotWindows(p)
    set snap to {}
    tell application "System Events"
        repeat with w in (windows of p)
            try
                set end of snap to contents of w
            end try
        end repeat
    end tell
    return snap
end snapshotWindows


on tileWindowsInFrame(wins, sx, sy, sw, sh)
    set winCount to count of wins
    if winCount = 0 then return 0

    set layout to my rowLayout(winCount)
    set rowCount to count of layout
    set rowH to sh div rowCount

    set placed to 0
    set idx to 1
    repeat with rowI from 1 to rowCount
        set cellsInRow to item rowI of layout
        set cellW to sw div cellsInRow
        repeat with colI from 0 to (cellsInRow - 1)
            if idx > winCount then exit repeat
            set tx to sx + (colI * cellW)
            set ty to sy + ((rowI - 1) * rowH)
            set w to item idx of wins
            tell application "System Events"
                try
                    set size of w to {cellW, rowH}
                    set position of w to {tx, ty}
                    set size of w to {cellW, rowH}
                    set position of w to {tx, ty}
                    set placed to placed + 1
                end try
            end tell
            set idx to idx + 1
        end repeat
    end repeat
    return placed
end tileWindowsInFrame


on tileAllApps(sx, sy, sw, sh)
    tell application "System Events"
        set procs to every process whose visible is true and background only is false
        set targetApps to {}
        repeat with p in procs
            try
                if (count of windows of p) > 0 then set end of targetApps to contents of p
            end try
        end repeat
    end tell

    set appCount to count of targetApps
    if appCount = 0 then
        do shell script "/usr/bin/osascript -e 'display notification \"No visible foreground apps with windows\" with title \"Dock Snap\"'"
        return
    end if

    set layout to my rowLayout(appCount)
    set rowCount to count of layout
    set rowH to sh div rowCount

    set appIdx to 1
    set totalWins to 0
    repeat with rowI from 1 to rowCount
        set cellsInRow to item rowI of layout
        set cellW to sw div cellsInRow
        repeat with colI from 0 to (cellsInRow - 1)
            if appIdx > appCount then exit repeat
            set tx to sx + (colI * cellW)
            set ty to sy + ((rowI - 1) * rowH)
            set a to item appIdx of targetApps
            set appWins to my snapshotWindows(a)
            repeat with w in appWins
                tell application "System Events"
                    try
                        set size of w to {cellW, rowH}
                        set position of w to {tx, ty}
                        set size of w to {cellW, rowH}
                        set position of w to {tx, ty}
                        set totalWins to totalWins + 1
                    end try
                end tell
            end repeat
            set appIdx to appIdx + 1
        end repeat
    end repeat

    tell application "System Events"
        repeat with a in (reverse of targetApps)
            try
                set frontmost of a to true
            end try
        end repeat
    end tell

    do shell script "/usr/bin/osascript -e 'display notification \"" & totalWins & " windows across " & (appIdx - 1) & " apps\" with title \"Dock Snap\"'"
end tileAllApps


on findProcessByName(targetName)
    set targetNameLC to do shell script "echo " & quoted form of targetName & " | tr '[:upper:]' '[:lower:]'"
    tell application "System Events"
        set procs to every process whose visible is true and background only is false
        repeat with p in procs
            set pName to name of p
            set pNameLC to do shell script "echo " & quoted form of pName & " | tr '[:upper:]' '[:lower:]'"
            if pNameLC contains targetNameLC then return contents of p
        end repeat
    end tell
    return missing value
end findProcessByName


on tileOneApp(targetName, sx, sy, sw, sh)
    set match to my findProcessByName(targetName)
    if match is missing value then
        do shell script "/usr/bin/osascript -e 'display notification \"No running app matching \\\"" & targetName & "\\\"\" with title \"Dock Snap\"'"
        return
    end if

    set wins to my snapshotWindows(match)
    set winCount to count of wins
    if winCount = 0 then
        do shell script "/usr/bin/osascript -e 'display notification \"" & (name of match) & " has no windows\" with title \"Dock Snap\"'"
        return
    end if

    set placed to my tileWindowsInFrame(wins, sx, sy, sw, sh)

    tell application "System Events"
        try
            set frontmost of match to true
        end try
    end tell

    do shell script "/usr/bin/osascript -e 'display notification \"" & (name of match) & ": " & placed & "/" & winCount & " windows tiled\" with title \"Dock Snap\"'"
end tileOneApp


-- Distribute one app's windows across all available screens (round-robin),
-- then tile per-screen.
on distributeAcrossScreens(targetName)
    set match to my findProcessByName(targetName)
    if match is missing value then
        do shell script "/usr/bin/osascript -e 'display notification \"No running app matching \\\"" & targetName & "\\\"\" with title \"Dock Snap\"'"
        return
    end if

    set wins to my snapshotWindows(match)
    set winCount to count of wins
    if winCount = 0 then return

    set screenCount to my screenCountInt()
    if screenCount ≤ 1 then
        -- Only one screen — just tile here.
        set frameStr to my screenFrame(0)
        set AppleScript's text item delimiters to " "
        set parts to text items of frameStr
        set sx to (item 1 of parts) as integer
        set sy to (item 2 of parts) as integer
        set sw to (item 3 of parts) as integer
        set sh to (item 4 of parts) as integer
        set AppleScript's text item delimiters to ""
        my tileWindowsInFrame(wins, sx, sy, sw, sh)
        return
    end if

    -- Partition windows round-robin into per-screen lists.
    set perScreen to {}
    repeat with s from 1 to screenCount
        set end of perScreen to {}
    end repeat
    repeat with i from 1 to winCount
        set targetScreen to ((i - 1) mod screenCount) + 1
        set the end of (item targetScreen of perScreen) to item i of wins
    end repeat

    set totalPlaced to 0
    repeat with s from 1 to screenCount
        set frameStr to my screenFrame(s - 1)
        set AppleScript's text item delimiters to " "
        set parts to text items of frameStr
        set sx to (item 1 of parts) as integer
        set sy to (item 2 of parts) as integer
        set sw to (item 3 of parts) as integer
        set sh to (item 4 of parts) as integer
        set AppleScript's text item delimiters to ""
        set placed to my tileWindowsInFrame(item s of perScreen, sx, sy, sw, sh)
        set totalPlaced to totalPlaced + placed
    end repeat

    tell application "System Events"
        try
            set frontmost of match to true
        end try
    end tell

    do shell script "/usr/bin/osascript -e 'display notification \"" & (name of match) & ": " & totalPlaced & " windows across " & screenCount & " screens\" with title \"Dock Snap\"'"
end distributeAcrossScreens
