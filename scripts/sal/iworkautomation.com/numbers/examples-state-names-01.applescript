set the headerTitles to {"Alabama", "Alaska", "Arizona", "Arkansas", "California", "Colorado", "Connecticut", "Delaware", "Florida", "Georgia", "Hawaii", "Idaho", "Illinois", "Indiana", "Iowa", "Kansas", "Kentucky", "Louisiana", "Maine", "Maryland", "Massachusetts", "Michigan", "Minnesota", "Mississippi", "Missouri", "Montana", "Nebraska", "Nevada", "New Hampshire", "New Jersey", "New Mexico", "New York", "North Carolina", "North Dakota", "Ohio", "Oklahoma", "Oregon", "Pennsylvania", "Rhode Island", "South Carolina", "South Dakota", "Tennessee", "Texas", "Utah", "Vermont", "Virginia", "Washington", "West Virginia", "Wisconsin", "Wyoming"}

tell application "Numbers"
	activate
	
	-- NOTE: This script assumes the use of 1 row header and 1 column header
	
	-- prompt the user for whether the header titles are to used as row or column headers
	display dialog "Use the state names as column headers or row headers?" buttons ¬
		{"Cancel", "Row Headers", "Column Headers"}
	set the userChoice to the button returned of the result
	if the userChoice is "Row Headers" then
		-- add one for the header
		set rowCount to (length of the headerTitles) + 1
		set the dialogMessage to "Enter the number of columns to add:"
	else
		-- add one for the header
		set columnCount to (length of the headerTitles) + 1
		set the dialogMessage to "Enter the number of rows to add:"
	end if
	
	-- prompt for the number of rows or columns to add
	repeat
		try
			display dialog dialogMessage default answer "3"
			set the elementCount to the text returned of the result as integer
			if the elementCount is greater than 0 then
				if the userChoice is "Row Headers" then
					-- add one for the header
					set columnCount to elementCount + 1
				else
					-- add one for the header
					set rowCount to elementCount + 1
				end if
				exit repeat
			end if
		on error number errorNumber
			if errorNumber is -128 then error number -128
		end try
	end repeat
	
	-- build and populate the table
	tell the front document
		tell the active sheet
			set thisTable to ¬
				make new table with properties ¬
					{row count:rowCount, column count:columnCount}
			tell thisTable
				if the userChoice is "Row Headers" then
					repeat with i from 1 to the count of the headerTitles
						set thisHeaderTitle to item i of the headerTitles
						set the value of cell 1 of row (i + 1) to thisHeaderTitle
					end repeat
				else
					repeat with i from 1 to the count of the headerTitles
						set thisHeaderTitle to item i of the headerTitles
						set the value of cell 1 of column (i + 1) to thisHeaderTitle
					end repeat
					set the alignment of row 1 to center
				end if
			end tell
		end tell
	end tell
end tell
