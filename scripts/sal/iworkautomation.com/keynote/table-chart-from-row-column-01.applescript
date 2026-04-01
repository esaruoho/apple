tell application "Keynote"
	activate
	try
		-- check for document
		if not (exists document 1) then error number 1000
		tell document 1
			try -- check for selected table
				tell current slide
					set the selectedTable to ¬
						(the first table whose class of selection range is range)
				end tell
			on error
				error number 1001
			end try
			tell selectedTable
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
				-- check for errors
				if (rowCount is not 1) and (columnCount is not 1) then
					error number 1002
				else if (rowCount is 1) and (columnCount is 1) then
					error number 1002
				end if
				if headerRowCount is greater than 1 then
					error number 1003
				end if
				if headerColumnCount is greater than 1 then
					error number 1004
				end if
				-- get the column names
				set columnNames to {}
				if headerColumnCount is not 0 then
					repeat with i from 1 to the count of theseColumns
						set thisValue to (the value of the first cell of (item i of theseColumns))
						if thisValue is not missing value then
							set the end of columnNames to thisValue
						end if
					end repeat
				end if
				-- get the row names
				set rowNames to {}
				if headerRowCount is not 0 then
					repeat with i from 1 to the count of theseRows
						set thisValue to (the value of the first cell of (item i of theseRows))
						if thisValue is not missing value then
							set the end of rowNames to thisValue
						end if
					end repeat
				end if
			end tell
			-- add the chart to a new slide inserted after the current slide
			if rowCount is greater than columnCount then
				-- a column is selected
				tell selectedTable
					set thisColumn to item 1 of theseColumns
					set footerOffset to ((1 + footerRowCount) * -1)
					set dataSet to ¬
						(the value of cells (headerColumnCount + 1) thru footerOffset of thisColumn)
				end tell
				set thisSlide to ¬
					make new slide at after (get current slide) with properties ¬
						{base slide:master slide "Title - Top"}
				tell thisSlide
					set the object text of the default title item to (item 1 of the columnNames)
					add chart row names columnNames column names rowNames ¬
						data {dataSet} type pie_2d group by chart column
				end tell
			else
				-- a row is selected
				tell selectedTable
					set thisRow to item 1 of theseRows
					set footerOffset to ((1 + footerRowCount) * -1)
					set dataSet to ¬
						(the value of cells (headerRowCount + 1) thru footerOffset of thisRow)
				end tell
				set thisSlide to ¬
					make new slide at after (get current slide) with properties ¬
						{base slide:master slide "Title - Top"}
				tell thisSlide
					set the object text of the default title item to (item 1 of the rowNames)
					add chart row names rowNames column names columnNames ¬
						data {dataSet} type pie_2d group by chart column
				end tell
			end if
		end tell
	on error errorMessage number errorNumber
		if errorNumber is 1000 then
			set alertString to "MISSING RESOURCE"
			set errorMessage to ¬
				"Please create or open a document before running this script."
		else if errorNumber is 1001 then
			set alertString to "SELECTION ERROR"
			set errorMessage to "Please select a table before running this script."
		else if errorNumber is 1002 then
			set alertString to "SELECTION ERROR"
			set errorMessage to "Please select a single column or row."
		else if errorNumber is 1003 then
			set alertString to "TOO MANY ROW HEADERS"
			set errorMessage to ¬
				"This script is designed to work with no more than a single row header."
		else if errorNumber is 1004 then
			set alertString to "TOO MANY COLUMN HEADERS"
			set errorMessage to ¬
				"This script is designed to work with no more than a single column header."
		else
			set alertString to "EXECUTION ERROR"
		end if
		if errorNumber is not -128 then
			display alert alertString message errorMessage buttons {"Cancel"}
		end if
		error number -128
	end try
end tell
