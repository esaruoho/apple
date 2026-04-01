tell application "Keynote"
	activate
	try
		if not (exists document 1) then error number 1000
		tell document 1
			try
				tell current slide
					set the selectedTable to ¬
						(the first table whose class of selection range is range)
				end tell
			on error
				error number 1001
			end try
			tell selectedTable
				set selectionRangeID to the name of the selection range
				set theseCellIDs to the name of every cell of the selection range
				set cellCount to the count of theseCellIDs
				repeat with i from 1 to the cellCount
					set thisCell to cell (item i of theseCellIDs)
					if format of thisCell is percent then
						set thisValue to ((value of thisCell) * 100) as integer
						copy my getHighlightingColorsFor(thisValue) to ¬
							{thisTextColor, thisBackgroundColor}
						tell thisCell
							set text color to thisTextColor
							set background color to thisBackgroundColor
						end tell
					end if
				end repeat
				set selection range to range selectionRangeID
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

on getHighlightingColorsFor(thisValue)
	if thisValue is greater than or equal to 100 then
		return {{65535, 65535, 65535}, {13822, 5295, 2341}}
	else if thisValue is greater than or equal to 80 then
		return {{65535, 65535, 65535}, {27643, 10590, 4681}}
	else if thisValue is greater than or equal to 60 then
		return {{65535, 65535, 65535}, {41465, 15885, 7022}}
	else if thisValue is greater than or equal to 40 then
		return {{0, 0, 0}, {54873, 21393, 9792}}
	else if thisValue is greater than or equal to 20 then
		return {{0, 0, 0}, {57539, 32428, 23728}}
	else if thisValue is greater than or equal to 0 then
		return {{0, 0, 0}, {60204, 43464, 37664}}
	end if
end getHighlightingColorsFor
