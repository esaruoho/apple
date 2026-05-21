-- DockSnap.applescript
-- Tile windows into an auto-sized grid on the main screen.
--
-- Two modes:
--   no args               → every visible foreground app, one cell per app
--                           (every window of that app stacks in the cell)
--   <appname>             → just that app's windows tiled in a grid
--                           (case-insensitive substring match against process name)
--
-- Apple-native: NSScreen.main via /usr/bin/swift + System Events.

on run argv
    -- Optional app filter
    set targetName to ""
    if (count of argv) ≥ 1 then
        set targetName to item 1 of argv as text
    end if

    set screenInfo to do shell script "/usr/bin/swift -e 'import AppKit; let s = NSScreen.main!; let f = s.frame; let v = s.visibleFrame; let topY = f.size.height - (v.origin.y + v.size.height); print(\"\\(Int(v.origin.x)) \\(Int(topY)) \\(Int(v.size.width)) \\(Int(v.size.height))\")'"

    set AppleScript's text item delimiters to " "
    set parts to text items of screenInfo
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


on chooseGrid(n)
    if n ≤ 1 then return {1, 1}
    if n = 2 then return {2, 1}
    if n = 3 then return {3, 1}
    if n = 4 then return {2, 2}
    if n ≤ 6 then return {3, 2}
    if n ≤ 9 then return {3, 3}
    if n ≤ 12 then return {4, 3}
    if n ≤ 16 then return {4, 4}
    if n ≤ 20 then return {5, 4}
    if n ≤ 25 then return {5, 5}
    return {6, 5}
end chooseGrid


on tileAllApps(sx, sy, sw, sh)
    tell application "System Events"
        set procs to every process whose visible is true and background only is false
        set targetApps to {}
        repeat with p in procs
            try
                if (count of windows of p) > 0 then set end of targetApps to contents of p
            end try
        end repeat
        set appCount to count of targetApps
        if appCount = 0 then
            do shell script "/usr/bin/osascript -e 'display notification \"No visible foreground apps with windows\" with title \"Dock Snap\"'"
            return
        end if

        set gridDim to my chooseGrid(appCount)
        set gridCols to item 1 of gridDim
        set gridRows to item 2 of gridDim
        set cellW to sw div gridCols
        set cellH to sh div gridRows

        set idx to 0
        set windowsMoved to 0
        repeat with a in targetApps
            if idx ≥ (gridCols * gridRows) then exit repeat
            set colIdx to idx mod gridCols
            set rowIdx to idx div gridCols
            set tx to sx + (colIdx * cellW)
            set ty to sy + (rowIdx * cellH)
            try
                repeat with w in (windows of a)
                    try
                        set size of w to {cellW, cellH}
                        set position of w to {tx, ty}
                        set size of w to {cellW, cellH}
                        set position of w to {tx, ty}
                        set windowsMoved to windowsMoved + 1
                    end try
                end repeat
            end try
            set idx to idx + 1
        end repeat

        repeat with a in (reverse of targetApps)
            try
                set frontmost of a to true
            end try
        end repeat

        do shell script "/usr/bin/osascript -e 'display notification \"" & windowsMoved & " windows across " & idx & " apps in " & gridCols & "×" & gridRows & " grid\" with title \"Dock Snap\"'"
    end tell
end tileAllApps


on tileOneApp(targetName, sx, sy, sw, sh)
    set targetNameLC to do shell script "echo " & quoted form of targetName & " | tr '[:upper:]' '[:lower:]'"

    tell application "System Events"
        set procs to every process whose visible is true and background only is false
        set match to missing value
        repeat with p in procs
            set pName to name of p
            set pNameLC to do shell script "echo " & quoted form of pName & " | tr '[:upper:]' '[:lower:]'"
            if pNameLC contains targetNameLC then
                set match to contents of p
                exit repeat
            end if
        end repeat

        if match is missing value then
            do shell script "/usr/bin/osascript -e 'display notification \"No running app matching \\\"" & targetName & "\\\"\" with title \"Dock Snap\"'"
            return
        end if

        set wins to windows of match
        set winCount to count of wins
        if winCount = 0 then
            do shell script "/usr/bin/osascript -e 'display notification \"" & (name of match) & " has no windows\" with title \"Dock Snap\"'"
            return
        end if

        set gridDim to my chooseGrid(winCount)
        set gridCols to item 1 of gridDim
        set gridRows to item 2 of gridDim
        set cellW to sw div gridCols
        set cellH to sh div gridRows

        set idx to 0
        repeat with w in wins
            if idx ≥ (gridCols * gridRows) then exit repeat
            set colIdx to idx mod gridCols
            set rowIdx to idx div gridCols
            set tx to sx + (colIdx * cellW)
            set ty to sy + (rowIdx * cellH)
            try
                set size of w to {cellW, cellH}
                set position of w to {tx, ty}
                set size of w to {cellW, cellH}
                set position of w to {tx, ty}
            end try
            set idx to idx + 1
        end repeat

        set frontmost of match to true

        do shell script "/usr/bin/osascript -e 'display notification \"" & (name of match) & ": " & idx & " windows in " & gridCols & "×" & gridRows & " grid\" with title \"Dock Snap\"'"
    end tell
end tileOneApp
