-- tile-thirds.applescript
-- Triggers: thirds, applescript
-- Category: System Events
-- Place the three frontmost apps' main windows in three vertical columns on
-- the main screen. Order: frontmost LEFT, second MIDDLE, third RIGHT.
--
-- Companion to tile-side-by-side / tile-top-bottom. Same NSScreen.main visibleFrame +
-- two-pass resize-then-position + background-only filter pattern.

set screenInfo to do shell script "/usr/bin/swift -e 'import AppKit; let s = NSScreen.main!; let f = s.frame; let v = s.visibleFrame; let topY = f.size.height - (v.origin.y + v.size.height); print(\"\\(Int(v.origin.x)) \\(Int(topY)) \\(Int(v.size.width)) \\(Int(v.size.height))\")'"

set AppleScript's text item delimiters to " "
set parts to text items of screenInfo
set sx to (item 1 of parts) as integer
set sy to (item 2 of parts) as integer
set sw to (item 3 of parts) as integer
set sh to (item 4 of parts) as integer
set AppleScript's text item delimiters to ""

set thirdW to sw div 3

tell application "System Events"
    set procs to every process whose visible is true and background only is false

    set targetApps to {}
    repeat with p in procs
        try
            if (count of windows of p) > 0 then
                set end of targetApps to contents of p
                if (count of targetApps) = 3 then exit repeat
            end if
        end try
    end repeat

    if (count of targetApps) < 3 then
        do shell script "/usr/bin/osascript -e 'display notification \"Need 3 apps with windows open\" with title \"tile-thirds\"'"
        return
    end if

    set leftApp to item 1 of targetApps
    set midApp to item 2 of targetApps
    set rightApp to item 3 of targetApps
    set leftWin to window 1 of leftApp
    set midWin to window 1 of midApp
    set rightWin to window 1 of rightApp

    set size of leftWin to {thirdW, sh}
    set size of midWin to {thirdW, sh}
    set size of rightWin to {thirdW, sh}
    set position of leftWin to {sx, sy}
    set position of midWin to {sx + thirdW, sy}
    set position of rightWin to {sx + 2 * thirdW, sy}
end tell
