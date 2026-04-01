property rowCount : 10
property columnCount : 10
property useRowHeaders : true
property useColumnHeaders : true

tell application "Numbers"
	activate
	if not (exists document 1) then make new document
	tell document 1
		tell active sheet
			set thisTable to ¬
				make new table with properties ¬
					{row count:rowCount, column count:columnCount}
			tell thisTable
				set height of every row to 40
				set width of every column to 60
				if useRowHeaders is true then
					set startRowCellIndex to 2
				else
					set startRowCellIndex to 1
				end if
				if useColumnHeaders is true then
					set startColumnCellIndex to 3
				else
					set startColumnCellIndex to 2
				end if
				repeat with i from startColumnCellIndex to rowCount by 2
					-- define the cell range to merge
					set rangeStart to name of cell startRowCellIndex of row i
					set rangeEnd to name of cell -1 of row i
					set the rowRange to rangeStart & ":" & rangeEnd
					-- merge the specified range
					merge range rowRange
					tell cell 2 of row i -- format the merged area
						set background color to {59121, 59119, 59120}
						set text color to {46137, 46137, 46137}
						set alignment to center
						set vertical alignment to center
						set font size to 18.0
						set value to "▼"
					end tell
				end repeat
				set the selection range to cell range
			end tell
		end tell
	end tell
end tell
