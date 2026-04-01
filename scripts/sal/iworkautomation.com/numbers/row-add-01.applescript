-- This script adds a table summation cell to the bottom right of the selected table
-- NOTE: This script assumes the use of one row header and one column header
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
				-- store the address of the current non-header cell area
				set tableRangeAddress to (name of cell 2 of row 2) & ":" & (name of last cell)
				-- add a row to the end of the table
				add row below last row
				tell last row
					-- set style properties of new row
					set background color to {0, 0, 0}
					set text color to {65535, 65535, 65535}
					-- derive the range address of the cells to merge
					set the mergeRange to (name of second cell) & ":" & (name of cell -2)
				end tell
				-- merge all cells of the new row except the frist and last ones
				merge range mergeRange
				tell last row
					-- set the contents and style of merged cells
					set alignment of second cell to right
					set value of second cell to "TOTAL"
				end tell
				-- set formula of last cell to be SUM of table
				set the value of the last cell to ("=SUM(" & tableRangeAddress & ")")
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
