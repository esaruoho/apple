-- DockSnap.applescript
-- Tile EVERY currently-running visible app's main window into an auto-sized grid.
-- Foreground apps only (visible is true, background only is false), one window each.
-- Apple-native: NSScreen.main via /usr/bin/swift + System Events.
--
-- Grid sizes by app count:
--   1 → 1×1     2 → 1×2     3 → 1×3
--   4 → 2×2     5-6 → 2×3   7-9 → 3×3
--   10-12 → 3×4   13-16 → 4×4   17-20 → 4×5

set screenInfo to do shell script "/usr/bin/swift -e 'import AppKit; let s = NSScreen.main!; let f = s.frame; let v = s.visibleFrame; let topY = f.size.height - (v.origin.y + v.size.height); print(\"\\(Int(v.origin.x)) \\(Int(topY)) \\(Int(v.size.width)) \\(Int(v.size.height))\")'"

set AppleScript's text item delimiters to " "
set parts to text items of screenInfo
set sx to (item 1 of parts) as integer
set sy to (item 2 of parts) as integer
set sw to (item 3 of parts) as integer
set sh to (item 4 of parts) as integer
set AppleScript's text item delimiters to ""

tell application "System Events"
    set procs to every process whose visible is true and background only is false
    set targetApps to {}
    repeat with p in procs
        try
            if (count of windows of p) > 0 then
                set end of targetApps to contents of p
            end if
        end try
    end repeat

    set appCount to count of targetApps
    if appCount = 0 then
        do shell script "/usr/bin/osascript -e 'display notification \"No visible foreground apps with windows\" with title \"Dock Snap\"'"
        return
    end if

    -- Pick grid dimensions
    set gridCols to 1
    set gridRows to 1
    if appCount = 2 then
        set gridCols to 2
        set gridRows to 1
    else if appCount = 3 then
        set gridCols to 3
        set gridRows to 1
    else if appCount = 4 then
        set gridCols to 2
        set gridRows to 2
    else if appCount ≤ 6 then
        set gridCols to 3
        set gridRows to 2
    else if appCount ≤ 9 then
        set gridCols to 3
        set gridRows to 3
    else if appCount ≤ 12 then
        set gridCols to 4
        set gridRows to 3
    else if appCount ≤ 16 then
        set gridCols to 4
        set gridRows to 4
    else
        set gridCols to 5
        set gridRows to 4
    end if

    set cellW to sw div gridCols
    set cellH to sh div gridRows

    set idx to 0
    repeat with a in targetApps
        if idx ≥ (gridCols * gridRows) then exit repeat
        set colIdx to idx mod gridCols
        set rowIdx to idx div gridCols
        set targetX to sx + (colIdx * cellW)
        set targetY to sy + (rowIdx * cellH)
        try
            set win to window 1 of a
            -- Two-pass resize-then-position (Safari auto-adjust workaround).
            set size of win to {cellW, cellH}
            set position of win to {targetX, targetY}
            -- Bring app to front so it's not buried.
            set frontmost of a to true
        end try
        set idx to idx + 1
    end repeat

    do shell script "/usr/bin/osascript -e 'display notification \"Snapped " & idx & " apps in a " & gridCols & "×" & gridRows & " grid\" with title \"Dock Snap\"'"
end tell
