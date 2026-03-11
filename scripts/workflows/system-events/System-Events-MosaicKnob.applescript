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

	set showCount to showCount + direction
	if showCount < 1 then set showCount to 1

	-- Get screen info via Swift (avoids use framework + do shell script conflict)
	set screenInfo to do shell script "swift -e 'import AppKit; let s = NSScreen.main!.visibleFrame; let f = NSScreen.main!.frame; print(Int(s.origin.x), Int(f.size.height - s.origin.y - s.size.height), Int(s.size.width), Int(s.size.height))'"
	set sX to word 1 of screenInfo as integer
	set menuBarH to word 2 of screenInfo as integer
	set sW to word 3 of screenInfo as integer
	set sH to word 4 of screenInfo as integer

	tell application "System Events"
		set fp to first process whose frontmost is true
		set appName to name of fp
		set winCount to count of windows of fp
	end tell

	if winCount is 0 then return "No windows"
	if showCount > winCount then set showCount to winCount

	-- Save capped state
	do shell script "echo " & showCount & " > /tmp/mosaic-knob-state"

	-- Calculate best grid
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
		-- Tile the visible windows (move on-screen)
		repeat with i from 1 to showCount
			set idx to i - 1
			set c to idx mod bestCols
			set r to idx div bestCols
			set winX to sX + (c * cellW)
			set winY to menuBarH + (r * cellH)
			try
				set position of window i of fp to {winX, winY}
				set size of window i of fp to {cellW, cellH}
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
