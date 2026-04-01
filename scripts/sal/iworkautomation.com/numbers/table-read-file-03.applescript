property useHeaders : true

tell application "Numbers"
	activate
	try
		if not (exists document 1) then error number 1000
		tell document 1
			tell active sheet
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
				
				if useHeaders is true then
					set dataGroupCount to dataGroupCount + 1
					set dataSetCount to dataSetCount + 1
					set startingAdjustment to 1
				else
					set startingAdjustment to 0
				end if
				
				if groupingMethod is "Row" then
					set thisTable to ¬
						make new table with properties ¬
							{row count:dataGroupCount, column count:dataSetCount}
				else if groupingMethod is "Column" then
					set thisTable to ¬
						make new table with properties ¬
							{row count:dataSetCount, column count:dataGroupCount}
				end if
				
				-- import the data
				if the groupingMethod is "Row" then
					repeat with i from 1 to the count of thisTSVData
						set thisDataGroup to item i of thisTSVData
						tell row (i + startingAdjustment) of thisTable
							repeat with q from 1 to the count of thisDataGroup
								set the value of cell (q + startingAdjustment) to item q of thisDataGroup
							end repeat
						end tell
					end repeat
				else
					repeat with i from 1 to the count of thisTSVData
						set thisDataGroup to item i of thisTSVData
						tell column (i + startingAdjustment) of thisTable
							repeat with q from 1 to the count of thisDataGroup
								set the value of cell (q + startingAdjustment) to item q of thisDataGroup
							end repeat
						end tell
					end repeat
				end if
				
			end tell
		end tell
	on error errorMessage number errorNumber
		if errorNumber is 1000 then
			set alertString to "MISSING RESOURCE"
			set errorMessage to "Please create or open a document before running this script."
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
