-- TopBottom.applescript
-- Stack the two frontmost apps' main windows top + bottom on the main screen.
-- Frontmost app goes TOP, second-frontmost goes BOTTOM.
--
-- Companion to SideBySide.applescript. Same pattern: NSScreen.main visibleFrame
-- via /usr/bin/swift, two-pass resize-then-position, background-only filter.

set screenInfo to do shell script "/usr/bin/swift -e 'import AppKit; let s = NSScreen.main!; let f = s.frame; let v = s.visibleFrame; let topY = f.size.height - (v.origin.y + v.size.height); print(\"\\(Int(v.origin.x)) \\(Int(topY)) \\(Int(v.size.width)) \\(Int(v.size.height))\")'"

set AppleScript's text item delimiters to " "
set parts to text items of screenInfo
set sx to (item 1 of parts) as integer
set sy to (item 2 of parts) as integer
set sw to (item 3 of parts) as integer
set sh to (item 4 of parts) as integer
set AppleScript's text item delimiters to ""

set halfH to sh div 2

tell application "System Events"
    set procs to every process whose visible is true and background only is false

    set targetApps to {}
    repeat with p in procs
        try
            if (count of windows of p) > 0 then
                set end of targetApps to contents of p
                if (count of targetApps) = 2 then exit repeat
            end if
        end try
    end repeat

    if (count of targetApps) < 2 then
        do shell script "/usr/bin/osascript -e 'display notification \"Need 2 apps with windows open\" with title \"Top / Bottom\"'"
        return
    end if

    set topApp to item 1 of targetApps
    set bottomApp to item 2 of targetApps
    set topWin to window 1 of topApp
    set bottomWin to window 1 of bottomApp

    set size of topWin to {sw, halfH}
    set size of bottomWin to {sw, halfH}
    set position of topWin to {sx, sy}
    set position of bottomWin to {sx, sy + halfH}
end tell
