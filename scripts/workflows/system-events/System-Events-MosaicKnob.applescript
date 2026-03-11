-- Mosaic Knob: single script with two subroutines for Loupedeck knob.
-- Subroutine "more" = turn right = show one more window tiled.
-- Subroutine "less" = turn left = show one fewer window tiled.
-- State persisted in /tmp/mosaic-knob-state between turns.
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
	-- 1=1x1, 2=2x1, 3=3x1, 4=2x2, 6=3x2, 8=4x2, 9=3x3, 12=4x3, 16=4x4
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
		-- Find next valid step >= showCount
		repeat with s in validSteps
			if s as integer ≥ showCount then
				set showCount to s as integer
				exit repeat
			end if
		end repeat
	else
		set showCount to showCount - 1
		-- Find previous valid step <= showCount
		set best to 1
		repeat with s in validSteps
			if s as integer ≤ showCount then set best to s as integer
		end repeat
		set showCount to best
	end if
	if showCount < 1 then set showCount to 1

	tell application "System Events"
		set fp to first process whose frontmost is true
		set appName to name of fp
		set winCount to count of windows of fp
		-- Get frontmost window position to detect which screen it's on
		set winPos to position of window 1 of fp
		set wx to item 1 of winPos
		set wy to item 2 of winPos
	end tell

	-- Get screen info for the screen containing the frontmost window
	-- Uses comma delimiter because AppleScript's "word" eats negative signs
	set screenInfo to do shell script "swift -e '" & ¬
		"import AppKit; " & ¬
		"let wx = " & wx & ".0, wy = " & wy & ".0; " & ¬
		"let primaryH = NSScreen.screens[0].frame.size.height; " & ¬
		"let flipped = NSPoint(x: wx, y: primaryH - wy); " & ¬
		"var target = NSScreen.main!; " & ¬
		"for screen in NSScreen.screens { " & ¬
		"if screen.frame.contains(flipped) { target = screen; break } }; " & ¬
		"let vf = target.visibleFrame; let f = target.frame; " & ¬
		"print(\"\\(Int(vf.origin.x)),\\(Int(primaryH - vf.origin.y - vf.size.height)),\\(Int(vf.size.width)),\\(Int(vf.size.height))\")'"
	set AppleScript's text item delimiters to ","
	set parts to text items of screenInfo
	set sX to (item 1 of parts) as integer
	set menuBarH to (item 2 of parts) as integer
	set sW to (item 3 of parts) as integer
	set sH to (item 4 of parts) as integer
	set AppleScript's text item delimiters to ""

	if winCount is 0 then return "No windows"
	if showCount > winCount then set showCount to winCount

	-- Save capped state
	do shell script "echo " & showCount & " > /tmp/mosaic-knob-state"

	-- Calculate grid: prefer fewer rows (wider cells)
	-- floor(sqrt(n)) rows, ceil(n/rows) cols
	-- 1=1x1, 2=2x1, 3=3x1, 4=2x2, 5=3x2, 6=3x2, 9=3x3
	set bestRows to 1
	repeat while (bestRows + 1) * (bestRows + 1) ≤ showCount
		set bestRows to bestRows + 1
	end repeat
	set bestCols to ((showCount + bestRows - 1) div bestRows)

	set cellW to sW div bestCols
	set cellH to sH div bestRows

	tell application "System Events"
		-- Tile the visible windows: size first, then position
		-- (some apps like Safari adjust position after resize)
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

		-- Hide the rest off-screen (no dock animation)
		repeat with i from (showCount + 1) to winCount
			try
				set position of window i of fp to {-10000, -10000}
			end try
		end repeat
	end tell

	return appName & ": " & showCount & "/" & winCount
end doMosaic
