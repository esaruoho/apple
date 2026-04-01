tell application "Numbers"
	activate
	try
		if not (exists document 1) then error number 1000
		tell document 1
			try
				tell active sheet
					set the selectedTable to ¬
						(the first table whose class of selection range is range)
				end tell
			on error
				error number 1001
			end try
			
			-- set the default colors for intersection
			set the intersectionBackgroundColor to {65535, 65535, 65535} -- white
			set the intersectionTextColor to {0, 0, 0} -- black
			
			-- set the default colors for parent columns/rows
			set the backgroundColor to {52428, 26214, 65535}
			set the textColor to {65535, 65535, 65535}
			
			tell selectedTable
				set the selectionRange to the selection range
				
				-- get the parent columns and rows of the selection
				set theseColumns to the columns of selection range
				set theseRows to the rows of selection range
				
				-- format the parent columns
				repeat with i from 1 to the count of theseColumns
					set thisColumn to item i of theseColumns
					set the background color of thisColumn to backgroundColor
					set the text color of thisColumn to textColor
					set the font name of thisColumn to "Helvetica"
					set the font size of thisColumn to 15
				end repeat
				
				-- format the parent rows
				repeat with i from 1 to the count of theseRows
					set thisRow to item i of theseRows
					set the background color of thisRow to backgroundColor
					set the text color of thisRow to textColor
					set the font name of thisRow to "Helvetica"
					set the font size of thisRow to 15
				end repeat
				
				-- format the intersection
				set background color of selectionRange to intersectionBackgroundColor
				set the text color of selectionRange to intersectionTextColor
			end tell
		end tell
	on error errorMessage number errorNumber
		if errorNumber is 1000 then
			set alertString to "MISSING RESOURCE"
			set errorMessage to "Please create or open a document before running this script."
		else if errorNumber is 1001 then
			set alertString to "SELECTION ERROR"
			set errorMessage to "Please select a table before running this script."
		else
			set alertString to "EXECUTION ERROR"
		end if
		display alert alertString message errorMessage buttons {"Cancel"}
		error number -128
	end try
end tell
