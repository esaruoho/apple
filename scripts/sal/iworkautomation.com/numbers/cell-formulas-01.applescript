property functionNames : {"SUM", "AVERAGE", "MIN", "MAX", "COUNT", "PRODUCT"}
property columnCount : 7
property rowCount : 8
property useColumnHeaders : true
property useRowHeaders : true

tell application "Numbers"
	activate
	if not (exists document 1) then make new document
	tell document 1
		tell active sheet
			set thisTable to ¬
				make new table with properties ¬
					{row count:rowCount, column count:columnCount}
			tell thisTable
				if useRowHeaders is true then
					set columnStartIndex to 2
				else
					set columnStartIndex to 1
				end if
				set x to 1
				repeat with i from 2 to the columnCount
					set thisFunction to item x of functionNames
					tell column i
						set alignment to center
						set vertical alignment to center
						set the value of cell 1 to thisFunction
						repeat with q from 2 to (rowCount - 1)
							set the value of cell q to q
						end repeat
						set the rangeStart to the name of cell 2
						set the rangeEnd to the name of cell -2
						set thisFormula to ¬
							"=" & thisFunction & "(" & rangeStart & ":" & rangeEnd & ")"
						set the value of the last cell to thisFormula
					end tell
					set x to x + 1
				end repeat
				tell the last row
					set the background color to {0, 0, 0}
					set the text color to {65535, 65535, 65535}
				end tell
			end tell
		end tell
	end tell
end tell
