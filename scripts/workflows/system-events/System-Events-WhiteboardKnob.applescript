-- WhiteboardKnob: Browse ALL whiteboards across ~/work/ and ~/.claude/skills/ with a Loupedeck knob.
-- Button press (browse): scans all PNGs into a flat list. No dialogs — just loads and starts.
-- Knob right (next): show next board.
-- Knob left (prev): show previous board.
-- Knob press (open): open current board in Preview for full viewing.
-- State files:
--   /tmp/whiteboard-knob-files  (flat list of all PNG paths, one per line)
--   /tmp/whiteboard-knob-index  (current position, 1-based)
--   /tmp/whiteboard-knob-current (current PNG path — bridge to ray-graph + holodeck)
-- Loupedeck: file=WhiteboardKnob.scpt
--   Button:     subroutine=browse
--   Knob RIGHT: subroutine=next
--   Knob LEFT:  subroutine=prev
--   Knob PRESS: subroutine=open

on browse()
	-- Scan ALL whiteboards into a flat sorted list — no dialogs, no picking
	do shell script "find ~/work/ ~/.claude/skills/ \\( -path '*/boards/*.png' -o -path '*/whiteboards/*.png' \\) 2>/dev/null | sort > /tmp/whiteboard-knob-files"

	set total to (do shell script "wc -l < /tmp/whiteboard-knob-files") as integer
	if total is 0 then
		display notification "No whiteboards found" with title "WhiteboardKnob"
		return
	end if

	do shell script "echo 1 > /tmp/whiteboard-knob-index"
	display notification (total as text) & " whiteboards loaded" with title "WhiteboardKnob"
	showCurrentBoard()
end browse

on next()
	navigateBoard(1)
end next

on prev()
	navigateBoard(-1)
end prev

on |open|()
	-- Open current board in Preview for full viewing
	try
		set idx to (do shell script "cat /tmp/whiteboard-knob-index") as integer
		set total to (do shell script "wc -l < /tmp/whiteboard-knob-files") as integer
	on error
		display notification "Press Browse first to load whiteboards" with title "WhiteboardKnob"
		return
	end try

	if total is 0 then
		display notification "No whiteboards loaded" with title "WhiteboardKnob"
		return
	end if
	if idx > total then set idx to total
	if idx < 1 then set idx to 1

	set boardPath to do shell script "sed -n '" & idx & "p' /tmp/whiteboard-knob-files"
	do shell script "open -a Preview " & quoted form of boardPath
end |open|

on navigateBoard(direction)
	try
		set idx to (do shell script "cat /tmp/whiteboard-knob-index") as integer
		set total to (do shell script "wc -l < /tmp/whiteboard-knob-files") as integer
	on error
		display notification "Press Browse first to load whiteboards" with title "WhiteboardKnob"
		return
	end try

	if total is 0 then
		display notification "No whiteboards loaded" with title "WhiteboardKnob"
		return
	end if

	set idx to idx + direction
	if idx < 1 then set idx to total -- wrap around
	if idx > total then set idx to 1 -- wrap around

	do shell script "echo " & idx & " > /tmp/whiteboard-knob-index"
	showCurrentBoard()
end navigateBoard

on showCurrentBoard()
	set idx to (do shell script "cat /tmp/whiteboard-knob-index") as integer
	set total to (do shell script "wc -l < /tmp/whiteboard-knob-files") as integer
	if total is 0 then
		display notification "No boards found" with title "WhiteboardKnob"
		return
	end if
	if idx > total then set idx to total
	if idx < 1 then set idx to 1

	set boardPath to do shell script "sed -n '" & idx & "p' /tmp/whiteboard-knob-files"

	-- Extract just the filename for display
	set AppleScript's text item delimiters to "/"
	set boardName to last text item of boardPath
	set AppleScript's text item delimiters to ""

	-- Show notification with position
	display notification boardName with title "WhiteboardKnob " & idx & "/" & total

	-- Write current board path for virtual camera bridge
	do shell script "echo " & quoted form of boardPath & " > /tmp/whiteboard-knob-current"
end showCurrentBoard
