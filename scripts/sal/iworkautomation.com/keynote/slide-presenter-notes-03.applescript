tell application "OmniOutliner"
	activate
	try
		if not (exists document 1) then error number 10000
		
		display dialog "This script will replace the presenter notes of the active slides of the frontmost Keynote presentation, with the contents of this outline." & return & return & "The contents of each row will become the presenter notes of a corresponding Keynote slide." with icon 1
		
		tell application "Keynote"
			activate
			if not (exists document 1) then error number 10001
			
			tell front document
				set the slideCount to the count of (slides whose skipped is false)
			end tell
		end tell
		
		tell the front document
			set theseOutlinerNotes to the topic of every row
		end tell
		
		if the (count of theseOutlinerNotes) is greater than the slideCount then
			error number 10002
		else if the (count of theseOutlinerNotes) is less than the slideCount then
			error number 10003
		end if
	on error errorMessage number errorNumber
		if errorNumber is 10000 then
			set errorMessage to "No document is open."
		else if errorNumber is 10001 then
			set errorMessage to "No presentation is open."
		else if errorNumber is 10002 then
			set errorMessage to ¬
				"There are more rows in this document than there are active slides in the presentation."
		else if errorNumber is 10003 then
			set errorMessage to ¬
				"There are fewer rows in this document than there are active slides in the presentation."
		end if
		if errorNumber is not -128 then
			display alert "PREPARATION ERROR" message errorMessage
		end if
		error number -128
	end try
end tell

tell application "Keynote"
	activate
	tell front document
		-- get a list of the active slides
		set theseSlides to (every slide of it whose skipped is false)
		repeat with i from 1 to the count of theseSlides
			set thisSlide to item i of theseSlides
			set the presenter notes of thisSlide to item i of theseOutlinerNotes
		end repeat
	end tell
	display dialog "The transfer of presenter notes has completed." buttons {"OK"} default button 1
end tell
