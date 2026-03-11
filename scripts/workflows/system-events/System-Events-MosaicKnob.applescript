-- Mosaic Knob: Loupedeck slider/knob controls window density
-- Argument: 0-127 (MIDI-style). 0 = one window full screen, 127 = all windows mosaic.
-- In between = proportional number of windows tiled, rest minimized.
-- Loupedeck: osascript /Users/esaruoho/work/apple/scripts/workflows/system-events/System-Events-MosaicKnob.applescript {knob_value}

use framework "AppKit"

on run argv
	if (count of argv) is 0 then return "Usage: osascript MosaicKnob.applescript {0-127}"
	set knobVal to (item 1 of argv) as integer
	if knobVal < 0 then set knobVal to 0
	if knobVal > 127 then set knobVal to 127

	-- Get usable screen area (excludes menu bar + Dock)
	set mainScreen to current application's NSScreen's mainScreen()
	set screenFrame to mainScreen's visibleFrame()
	set sX to (item 1 of item 1 of screenFrame) as integer
	set sY to (item 2 of item 1 of screenFrame) as integer
	set sW to (item 1 of item 2 of screenFrame) as integer
	set sH to (item 2 of item 2 of screenFrame) as integer
	set mainFrame to mainScreen's frame()
	set totalH to (item 2 of item 2 of mainFrame) as integer
	set menuBarH to totalH - sH - sY

	tell application "System Events"
		set fp to first process whose frontmost is true
		set appName to name of fp
		set winList to every window of fp
		set winCount to count of winList
	end tell

	if winCount is 0 then return "No windows"

	-- Map 0-127 to 1..winCount
	if winCount is 1 then
		set showCount to 1
	else
		set showCount to 1 + ((knobVal * (winCount - 1)) div 127)
		if showCount > winCount then set showCount to winCount
		if showCount < 1 then set showCount to 1
	end if

	-- Calculate best grid for visible windows
	set bestCols to 1
	set bestRows to showCount
	set bestRatio to 999
	repeat with c from 1 to showCount
		set r to ((showCount + c - 1) div c)
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

	tell application "System Events"
		-- Tile the visible windows
		repeat with i from 1 to showCount
			set idx to i - 1
			set c to idx mod bestCols
			set r to idx div bestCols
			set winX to sX + (c * cellW)
			set winY to menuBarH + (r * cellH)
			-- Unminimize if needed (set visible won't work on minimized windows directly)
			try
				set position of window i of fp to {winX, winY}
				set size of window i of fp to {cellW, cellH}
			end try
		end repeat

		-- Minimize the rest
		repeat with i from (showCount + 1) to winCount
			try
				click (first button of window i of fp whose subrole is "AXMinimizeButton")
			end try
		end repeat
	end tell

	return appName & ": showing " & showCount & "/" & winCount & " in " & bestCols & "x" & bestRows
end run
