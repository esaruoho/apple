tell application "Numbers"
	activate
	-- for this example script, generate some random data sets
	set generatedData to my generateRandomNumericDataSets(8, 3)
	-- determine column count based on data length
	-- determine row count based on length of first item of data
	-- add 1 to row and column count if table is to include headers
	set useHeaders to true -- change to false to omit headers
	if useHeaders is true then
		set the columnCount to (the count of generatedData) + 1
		set the rowCount to (the count of item 1 of generatedData) + 1
	else
		set the columnCount to the count of generatedData
		set the rowCount to the count of item 1 of generatedData
	end if
	tell document 1
		tell active sheet
			set thisTable to ¬
				make new table with properties ¬
					{row count:rowCount, column count:columnCount, name:"Column Data Table"}
			tell thisTable
				if useHeaders is true then
					-- set the starting indexes for using headers
					set rowIndex to 1
					set columnIndex to 1
					-- since headers are used, name the column & row headers
					-- title and style the column header cells
					set x to 1
					repeat with i from 2 to the columnCount
						tell cell 1 of column i
							-- set the value and styling of the cell
							set value to "COL " & (x as string)
							set alignment to center
							set vertical alignment to center
						end tell
						set x to x + 1
					end repeat
					-- title and style the row header cells
					set x to 1
					repeat with i from 2 to the rowCount
						tell cell 1 of row i
							-- set the value and styling of the cell
							set value to "ROW " & (x as string)
							set alignment to right
							set vertical alignment to center
						end tell
						set x to x + 1
					end repeat
				else
					-- set the starting indexes for not using headers
					set rowIndex to 0
					set columnIndex to 0
				end if
				-- populate the table with the data
				set the columnCellCount to count of cells of column 2
				repeat with i from 1 to count of the generatedData
					-- get a data set from the data set list
					set thisColumnData to item i of the generatedData
					tell column (columnIndex + i)
						-- iterate the data set, populating column cells from top to bottom
						repeat with q from 1 to the count of thisColumnData
							-- set the value and styling of the cell
							tell cell (rowIndex + q)
								set value to item q of thisColumnData
								set alignment to center
								set vertical alignment to center
							end tell
						end repeat
					end tell
				end repeat
			end tell
		end tell
	end tell
end tell

on generateRandomNumericDataSets(setCount, setItemCount)
	set randomNumericDataSets to {}
	repeat setCount times
		set thisSet to {}
		repeat setItemCount times
			set the end of thisSet to (random number from -100 to 100)
		end repeat
		set the end of randomNumericDataSets to thisSet
	end repeat
	return randomNumericDataSets
end generateRandomNumericDataSets
