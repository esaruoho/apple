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
			tell selectedTable
				-- currently, use of headers and footers cannot be determined by a script.
				-- make the following assumptions:
				set usesHeaders to true -- assume 1 row and 1 column
				set usesFooters to false -- assume 1 row
				-- add a new column
				add column after last column
				set the summationColumn to the last column
				-- set the formula of each cell of the summation column
				tell summationColumn
					if usesHeaders is true then
						set startIndex to 2
					else
						set startIndex to 1
					end if
					repeat with i from startIndex to the count of cells
						-- get the row of the cell
						set thisRow to the row of cell i
						-- determine range coordinates
						set the rangeStart to the name of cell startIndex of thisRow
						set the rangeEnd to the name of cell -2 of thisRow
						-- create formula using SUM function
						set the summationFormula to ¬
							("=SUM(" & rangeStart & ":" & rangeEnd & ")") as string
						-- set the formula to the cell
						set the value of cell i to summationFormula
					end repeat
				end tell
			end tell
		end tell
	on error errorMessage number errorNumber
		if errorNumber is 1000 then
			set alertString to "MISSING RESOURCE"
			set errorMessage to ¬
				"Please create or open a document before running this script."
		else if errorNumber is 1001 then
			set alertString to "SELECTION ERROR"
			set errorMessage to ¬
				"Please select a table before running this script."
		else
			set alertString to "EXECUTION ERROR"
		end if
		if errorNumber is not -128 then
			display alert alertString message errorMessage buttons {"Cancel"}
		end if
		error number -128
	end try
end tell
