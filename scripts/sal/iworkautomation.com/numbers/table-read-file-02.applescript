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
				-- determine the attributes of the selection range
				set the selectionRowCount to count of rows of selection range
				set the selectionColumnCount to count of columns of selection range
				set the selectedCellNames to the name of every cell of the selection range
				set the selectedCellCount to the length of the selectedCellNames
				
				-- prompt user for the TSV file to read
				set thisTSVFile to ¬
					(choose file of type "public.tab-separated-values-text" with prompt ¬
						"Pick the TSV (tab separated values) file to import:")
				
				-- read the data
				set thisTSVData to my readTabSeparatedValuesFile(thisTSVFile)
				
				-- determine data structure
				set the dataGroupCount to the count of thisTSVData
				set the dataSetCount to the count of item 1 of thisTSVData
				
				-- create read data summary
				set the infoMessage to ¬
					"The read TSV data is composed of " & dataGroupCount & ¬
					" groups, with each group containing " & dataSetCount & " items." & ¬
					return & return
				
				-- prompt for desired data layout method
				set dialogMessage to ¬
					infoMessage & "Is the tabbed data to be grouped by row or column?"
				display dialog dialogMessage ¬
					buttons {"Cancel", "Row", "Column"} default button 1 with icon 1
				set the groupingMethod to the button returned of the result
				
				-- check to see that data parameters match the selection parameters
				if the groupingMethod is "Row" then
					if selectionRowCount is not equal to dataGroupCount then ¬
						error "SELECTION MISMATCH. " & ¬
							"The number of rows in the table selection (" & selectionRowCount & ¬
							"), does not match the count of rows in the imported data (" & ¬
							dataGroupCount & ")."
					if selectionColumnCount is not equal to dataSetCount then ¬
						error "SELECTION MISMATCH. " & ¬
							"The number of columns in the table selection (" & selectionColumnCount & ¬
							"), does not match the count of columns in the imported data (" & ¬
							dataSetCount & ")."
				else
					if selectionColumnCount is not equal to dataGroupCount then ¬
						error "SELECTION MISMATCH. " & ¬
							"The number of columns in the table selection (" & selectionColumnCount & ¬
							"), does not match the count of columns in the imported data (" & ¬
							dataGroupCount & ")."
					if selectionRowCount is not equal to dataSetCount then ¬
						error "SELECTION MISMATCH. " & ¬
							"The number of rows in the table selection (" & selectionRowCount & ¬
							"), does not match the count of rows in the imported data (" & ¬
							dataSetCount & ")."
				end if
				
				-- THE SELECTED CELLS WILL BE TARGETED USING THEIR CELL NAMES
				-- So order the cell name list to be all cells by row or column
				if the groupingMethod is "Row" then
					-- by default, Numbers provides cell names by top to bottom row, left to right
					set the orderedCellNames to selectedCellNames
					-- {"B2", "C2", "D2", "E2", "F2", "B3", "C3", "D3", "E3", "F3", "B4", "C4", "D4", "E4", "F4"}
				else
					-- sort the row-based list of cell names to column-based
					set the orderedCellNames to {}
					set groupCount to selectedCellCount div selectionRowCount
					repeat with i from 1 to groupCount
						repeat with q from i to selectedCellCount by groupCount
							set the end of the orderedCellNames to item q of selectedCellNames
						end repeat
					end repeat
					-- {"B2", "B3", "B4", "C2", "C3", "C4", "D2", "D3", "D4", "E2", "E3", "E4", "F2", "F3", "F4"}
				end if
				
				-- import the data
				set counter to 1
				repeat with i from 1 to the count of thisTSVData
					set thisDataGroup to item i of thisTSVData
					repeat with q from 1 to the count of thisDataGroup
						set the targetCellName to item counter of orderedCellNames
						set the value of cell targetCellName to item q of thisDataGroup
						set the counter to counter + 1
					end repeat
				end repeat
				
				(*
				set font size of selection range to 16
				set alignment of selection range to center
				*)
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
		if errorNumber is not -128 then
			display alert alertString message errorMessage buttons {"Cancel"}
		end if
		error number -128
	end try
end tell

on readTabSeparatedValuesFile(thisTSVFile)
	try
		set dataBlob to (every paragraph of (read thisTSVFile))
		set the tableData to {}
		set AppleScript's text item delimiters to tab
		repeat with i from 1 to the count of dataBlob
			set the end of the tableData to ¬
				(every text item of (item i of dataBlob))
		end repeat
		set AppleScript's text item delimiters to ""
		return tableData
	on error errorMessage number errorNumber
		set AppleScript's text item delimiters to ""
		error errorMessage number errorNumber
	end try
end readTabSeparatedValuesFile
