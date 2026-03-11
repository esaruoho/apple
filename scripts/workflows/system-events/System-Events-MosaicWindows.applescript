-- Mosaic Windows: tile all windows of the frontmost app into a grid
-- Uses NSScreen visibleFrame to respect menu bar and Dock.
-- Grid auto-selects best layout (closest to 16:10 aspect ratio per cell).
-- 1 window = maximize. 2 = side by side. 4 = 2x2. 6 = 3x2. etc.
-- Loupedeck: osascript /Users/esaruoho/work/apple/scripts/workflows/system-events/System-Events-MosaicWindows.applescript

use framework "AppKit"

-- Get usable screen area (excludes menu bar + Dock)
set mainScreen to current application's NSScreen's mainScreen()
set screenFrame to mainScreen's visibleFrame()
set sX to (item 1 of item 1 of screenFrame) as integer
set sY to (item 2 of item 1 of screenFrame) as integer
set sW to (item 1 of item 2 of screenFrame) as integer
set sH to (item 2 of item 2 of screenFrame) as integer
-- Convert NSScreen bottom-left origin to System Events top-left origin
set mainFrame to mainScreen's frame()
set totalH to (item 2 of item 2 of mainFrame) as integer
set menuBarH to totalH - sH - sY

tell application "System Events"
	set fp to first process whose frontmost is true
	set appName to name of fp
	set winList to every window of fp
	set winCount to count of winList
end tell

if winCount is 0 then return "No windows to arrange"

if winCount is 1 then
	tell application "System Events"
		set position of window 1 of fp to {sX, menuBarH}
		set size of window 1 of fp to {sW, sH}
	end tell
	return appName & ": 1 window maximized"
end if

-- Calculate best grid (closest to 16:10 aspect ratio per cell)
set bestCols to 1
set bestRows to winCount
set bestRatio to 999
repeat with c from 1 to winCount
	set r to ((winCount + c - 1) div c)
	set cellW2 to sW / c
	set cellH2 to sH / r
	set ratio to cellW2 / cellH2
	set diff to (ratio - 1.6)
	if diff < 0 then set diff to diff * -1
	if diff < bestRatio then
		set bestRatio to diff
		set bestCols to c
		set bestRows to r
	end if
end repeat

set cellW to sW div bestCols
set cellH to sH div bestRows

-- Position each window in the grid
tell application "System Events"
	repeat with i from 1 to winCount
		set idx to i - 1
		set c to idx mod bestCols
		set r to idx div bestCols
		set winX to sX + (c * cellW)
		set winY to menuBarH + (r * cellH)
		set position of window i of fp to {winX, winY}
		set size of window i of fp to {cellW, cellH}
	end repeat
end tell

return appName & ": " & winCount & " windows in " & bestCols & "x" & bestRows & " grid"
