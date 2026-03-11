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
