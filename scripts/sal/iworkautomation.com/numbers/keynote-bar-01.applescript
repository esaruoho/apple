tell application "Numbers"
	activate
	try
		-- check for document
		if not (exists document 1) then error number 1000
		tell document 1
			try -- check for selected table
				tell active sheet
					set the selectedTable to ¬
						(the first table whose class of selection range is range)
				end tell
			on error
				error number 1001
			end try
			tell selectedTable
				set thisTableName to its name
				-- get the count fo the various headers and footers
				set the headerColumnCount to header column count
				set the headerRowCount to header row count
				set the footerRowCount to footer row count
				-- store references to the intersecting columns and rows
				set theseRows to the rows of the selection range
				set theseColumns to the columns of the selection range
				-- get the row and column counts
				set rowCount to (count of theseRows)
				set columnCount to (count of theseColumns)
				-- get the column names
				set columnNames to {}
				if headerColumnCount is 1 then
					repeat with i from 1 to the count of theseColumns
						set thisValue to (the value of the first cell of (item i of theseColumns))
						if thisValue is not missing value then
							set the end of columnNames to thisValue
						end if
					end repeat
				else -- use the Column IDs
					repeat with i from 1 to the count of theseColumns
						set thisValue to the name of (item i of theseColumns)
						if thisValue is not missing value then
							set the end of columnNames to thisValue
						end if
					end repeat
				end if
				-- get the row names
				set rowNames to {}
				if headerRowCount is 1 then
					repeat with i from 1 to the count of theseRows
						set thisValue to (the value of the first cell of (item i of theseRows))
						if thisValue is not missing value then
							set the end of rowNames to thisValue
						end if
					end repeat
				else -- use row IDs
					repeat with i from 1 to the count of theseRows
						set thisValue to the name of (item i of theseRows)
						if thisValue is not missing value then
							set the end of rowNames to thisValue
						end if
					end repeat
				end if
			end tell
			
			set dataSets to {}
			repeat with i from 1 to rowCount
				set thisRow to item i of theseRows
				set thisDataSet to ¬
					(the value of cells (headerRowCount + 1) thru -1 of thisRow)
				set the end of the dataSets to thisDataSet
			end repeat
		end tell
	on error errorMessage number errorNumber
		if errorNumber is 1000 then
			set alertString to "MISSING RESOURCE"
			set errorMessage to ¬
				"Please create or open a document before running this script."
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

tell application "Keynote"
	activate
	try
		if not (exists document 1) then make new document
		tell the front document
			set thisSlide to ¬
				make new slide at after (get current slide) with properties ¬
					{base slide:master slide "Title - Top"}
			tell thisSlide
				set slideTitle to thisTableName
				set the object text of the default title item to slideTitle
				add chart row names rowNames column names columnNames ¬
					data dataSets type vertical_bar_2d group by chart column
			end tell
		end tell
	on error errorMessage number errorNumber
		if errorNumber is not -128 then
			display alert errorNumber message errorMessage buttons {"Cancel"}
		end if
	end try
end tell
