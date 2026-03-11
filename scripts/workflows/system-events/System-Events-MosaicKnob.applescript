-- Mosaic Knob: single script with two subroutines for Loupedeck knob.
-- Subroutine "more" = turn right = show one more window tiled.
-- Subroutine "less" = turn left = show one fewer window tiled.
-- State persisted in /tmp/mosaic-knob-state between turns.
-- Always tiles on the MAIN screen (the one with keyboard focus).
-- Loupedeck knob LEFT:  file=MosaicKnob.scpt, subroutine=less
-- Loupedeck knob RIGHT: file=MosaicKnob.scpt, subroutine=more

on more()
	doMosaic(1)
end more

on less()
	doMosaic(-1)
end less

on doMosaic(direction)
	-- Valid steps: only counts that fill the grid with no empty cells
	set validSteps to {1, 2, 3, 4, 6, 8, 9, 12, 16}

	-- Read current state
	try
		set showCount to (do shell script "cat /tmp/mosaic-knob-state") as integer
	on error
		if direction is 1 then
			set showCount to 1
		else
			set showCount to 999
		end if
	end try

	-- Jump to next/previous valid step
	if direction is 1 then
		set showCount to showCount + 1
		repeat with s in validSteps
			if (s as integer) is greater than or equal to showCount then
				set showCount to s as integer
				exit repeat
			end if
		end repeat
	else
		set showCount to showCount - 1
		set best to 1
		repeat with s in validSteps
			if (s as integer) is less than or equal to showCount then set best to s as integer
		end repeat
		set showCount to best
	end if
	if showCount < 1 then set showCount to 1

	-- Get MAIN screen geometry (keyboard focus screen) via Swift
	set screenInfo to do shell script "swift -e 'import AppKit; let s = NSScreen.main!; let vf = s.visibleFrame; let f = s.frame; let menuH = Int(f.size.height - vf.size.height - vf.origin.y); print(\"\\(Int(vf.origin.x)),\\(menuH),\\(Int(vf.size.width)),\\(Int(vf.size.height))\")'"
	set AppleScript's text item delimiters to ","
	set parts to text items of screenInfo
	set sX to (item 1 of parts) as integer
	set menuBarH to (item 2 of parts) as integer
	set sW to (item 3 of parts) as integer
	set sH to (item 4 of parts) as integer
	set AppleScript's text item delimiters to ""

	tell application "System Events"
		set fp to first process whose frontmost is true
		set appName to name of fp
		set winCount to count of windows of fp
	end tell

	if winCount is 0 then return "No windows"
	if showCount > winCount then set showCount to winCount

	-- Save capped state
	do shell script "echo " & showCount & " > /tmp/mosaic-knob-state"

	-- Calculate grid layout
	-- Small counts: explicit sensible layouts
	-- 1=full, 2=side-by-side, 3=three columns, 4=2x2
	-- Larger counts: optimize for 16:10 aspect ratio per cell
	if showCount is 1 then
		set bestCols to 1
		set bestRows to 1
	else if showCount is 2 then
		set bestCols to 2
		set bestRows to 1
	else if showCount is 3 then
		set bestCols to 3
		set bestRows to 1
	else if showCount is 4 then
		set bestCols to 2
		set bestRows to 2
	else
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
	end if

	set cellW to sW div bestCols
	set cellH to sH div bestRows

	tell application "System Events"
		-- Size first, then position (some apps adjust position after resize)
		repeat with i from 1 to showCount
			try
				set size of window i of fp to {cellW, cellH}
			end try
		end repeat
		repeat with i from 1 to showCount
			set idx to i - 1
			set c to idx mod bestCols
			set r to idx div bestCols
			set winX to sX + (c * cellW)
			set winY to menuBarH + (r * cellH)
			try
				set position of window i of fp to {winX, winY}
			end try
		end repeat

		-- Minimize the rest (clean, no off-screen hiding)
		repeat with i from (showCount + 1) to winCount
			try
				click (first button of window i of fp whose subrole is "AXMinimizeButton")
			end try
		end repeat
	end tell

	return appName & ": " & showCount & "/" & winCount
end doMosaic
