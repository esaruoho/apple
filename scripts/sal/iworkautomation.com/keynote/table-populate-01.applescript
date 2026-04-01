property useHeaders : true -- change to false to omit headers
property dataSetCount : 6
property dataSetItemCount : 3

tell application "Keynote"
	activate
	-- for this example script, generate some random data sets
	set generatedData to my generateRandomNumericDataSets(dataSetCount, dataSetItemCount)
	-- determine row count based on data length
	-- determine column count based on length of first item of data
	-- add 1 to row and column count if table is to include headers
	if useHeaders is true then
		set the rowCount to (the count of generatedData) + 1
		set the columnCount to (the count of item 1 of generatedData) + 1
	else
		set the rowCount to the count of generatedData
		set the columnCount to the count of item 1 of generatedData
	end if
	-- create and poplate a table reading the data as row based
	tell document 1
		tell current slide
			if useHeaders is true then
				set thisTable to ¬
					make new table with properties ¬
						{row count:rowCount, column count:columnCount, name:"Row Data Table", header row count:1, header column count:1}
			else
				set thisTable to ¬
					make new table with properties ¬
						{row count:rowCount, column count:columnCount, name:"Row Data Table", header row count:0, header column count:0}
			end if
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
				set the rowCellCount to count of cells of row 2
				repeat with i from 1 to count of the generatedData
					-- get a data set from the data set list
					set thisRowData to item i of the generatedData
					tell row (rowIndex + i)
						-- iterate the data set, populating row cells from left to right
						repeat with q from 1 to the count of thisRowData
							tell cell (columnIndex + q)
								set value to item q of thisRowData
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
