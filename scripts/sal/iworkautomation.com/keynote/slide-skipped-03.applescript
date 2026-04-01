tell application "Keynote"
	
	if not (exists document 1) then error number -128
	
	display dialog "Set this presentation to which zone?" buttons ¬
		{"JAPAN", "USA", "EUROPE"}
	set thisIdentifer to the button returned of the result
	
	tell the front document
		set the object text of the default body item of slide 1 to thisIdentifer
		
		repeat with i from 1 to the count of slides
			tell slide i
				set theseNotes to presenter notes
				if theseNotes is "" or theseNotes begins with thisIdentifer then
					set skipped to false
				else
					set skipped to true
				end if
			end tell
		end repeat
	end tell
	
	start the front document from the first slide of the front document
end tell
