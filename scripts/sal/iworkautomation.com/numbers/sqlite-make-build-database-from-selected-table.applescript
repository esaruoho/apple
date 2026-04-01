property extractDataWithFormatting : false
property coerceNumberToInteger : true
property documentsFolder : missing value

set documentsFolder to (path to documents folder)
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
			display dialog "This script will create an SQLite database with the data contained in the selected table." buttons {"Cancel", "Begin"} default button 2 with icon 1
			tell selectedTable
				set databaseName to the name of it
				
				tell application "Finder"
					if not (exists folder "Databases" of documentsFolder) then
						make new folder at documentsFolder with properties {name:"Databases"}
					end if
					
					set thisName to databaseName
					set loopCounter to 1
					repeat
						if exists document file (thisName & ".dbev") of folder "Databases" of documentsFolder then
							set thisName to databaseName & "-" & (loopCounter as string)
							set loopCounter to loopCounter + 1
						else
							set databaseName to thisName
							exit repeat
						end if
					end repeat
				end tell
				
				set rowCount to (the count of rows)
				set headerRowCount to header row count
				set headerColumnCount to header column count
				
				if headerRowCount is not 1 then error number 1002
				
				set the fieldNames to the value of cells (headerColumnCount + 1) thru -1 of row 1
				
				tell application "Database Events"
					close every database
					set targetDatabase to ¬
						make new database with properties {name:databaseName}
				end tell
				
				repeat with i from (1 + headerRowCount) to rowCount
					if extractDataWithFormatting is true then
						set thisRowData to the formatted value of every cell of row i
					else
						set thisRowData to the value of every cell of row i
					end if
					if coerceNumberToInteger is true then
						repeat with w from 1 to the count of thisRowData
							set thisDataItem to item w of thisRowData
							if the class of thisDataItem is in {real, number} then
								set item w of thisRowData to (thisDataItem as integer)
							end if
						end repeat
					end if
					tell application "Database Events"
						tell targetDatabase
							set thisRecord to make new record with properties {name:""}
							tell thisRecord
								repeat with q from 1 to the count of fieldNames
									set thisFieldName to item q of fieldNames
									set thisFieldData to item q of thisRowData
									make new field with properties ¬
										{name:thisFieldName, value:thisFieldData}
								end repeat
							end tell
						end tell
					end tell
				end repeat
			end tell
		end tell
		tell application "Database Events"
			tell targetDatabase
				save
			end tell
			quit
		end tell
		display dialog "The database has been created." buttons {"Reveal", "Done"} default button 2 with icon 1
		if the button returned of the result is "Reveal" then
			tell application "Finder"
				activate
				open folder "Databases" of documentsFolder
			end tell
		end if
	on error errorMessage number errorNumber
		if errorNumber is 1000 then
			set alertString to "MISSING RESOURCE"
			set errorMessage to "Please create or open a document before running this script."
		else if errorNumber is 1001 then
			set alertString to "SELECTION ERROR"
			set errorMessage to "Please select a table before running this script."
		else if errorNumber is 1002 then
			set alertString to "MISSING DATA"
			set errorMessage to "This script assumes the use of a single row header whose cell values will be used as field names in the created database."
		else
			set alertString to "EXECUTION ERROR"
		end if
		if errorNumber is not -128 then
			display alert alertString message errorMessage buttons {"Cancel"}
		end if
	end try
end tell
