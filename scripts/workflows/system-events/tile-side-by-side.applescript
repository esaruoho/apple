-- tile-side-by-side.applescript
-- Triggers: sidebyside, applescript
-- Category: System Events
-- Place the two frontmost apps' main windows side-by-side on the main screen.
-- Frontmost app goes LEFT, second-frontmost goes RIGHT.
--
-- Skips background-only processes (menu-bar utilities, agents).
-- Two-pass resize-then-position to work around Safari auto-adjust bug.
-- Uses NSScreen.main via /usr/bin/swift for accurate visibleFrame (excludes
-- menu bar + Dock). Apple-native.

-- Get main screen visible frame in TOP-LEFT coordinates.
set screenInfo to do shell script "/usr/bin/swift -e 'import AppKit; let s = NSScreen.main!; let f = s.frame; let v = s.visibleFrame; let topY = f.size.height - (v.origin.y + v.size.height); print(\"\\(Int(v.origin.x)) \\(Int(topY)) \\(Int(v.size.width)) \\(Int(v.size.height))\")'"

set AppleScript's text item delimiters to " "
set parts to text items of screenInfo
set sx to (item 1 of parts) as integer
set sy to (item 2 of parts) as integer
set sw to (item 3 of parts) as integer
set sh to (item 4 of parts) as integer
set AppleScript's text item delimiters to ""

set halfW to sw div 2

tell application "System Events"
    -- Visible, foregroundable apps in z-order (frontmost first).
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
        do shell script "/usr/bin/osascript -e 'display notification \"Need 2 apps with windows open\" with title \"Side by Side\"'"
        return
    end if

    set leftApp to item 1 of targetApps
    set rightApp to item 2 of targetApps
    set leftWin to window 1 of leftApp
    set rightWin to window 1 of rightApp

    -- Pass 1: resize both
    set size of leftWin to {halfW, sh}
    set size of rightWin to {halfW, sh}

    -- Pass 2: position (Safari + some apps auto-adjust after resize)
    set position of leftWin to {sx, sy}
    set position of rightWin to {sx + halfW, sy}
end tell
