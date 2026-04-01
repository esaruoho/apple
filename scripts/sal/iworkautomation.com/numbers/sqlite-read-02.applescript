tell application "Numbers"
	activate
	
	set targetDatabaseFile to ¬
		(POSIX path of (choose file with prompt ¬
			"Choose SQLite database file (.dbev):" default location (path to documents folder)))
end tell

tell application "Database Events"
	tell database targetDatabaseFile
		set the recordCount to the count of records
		-- example database uses first field for name, so field names are the rest
		set fieldNames to the name of fields 2 thru -1 of record 1
	end tell
end tell

tell application "Numbers"
	set thisDocument to make new document with properties ¬
		{document template:template "Blank"}
	tell thisDocument
		delete every table of the active sheet
		tell active sheet
			set thisTable to make new table with properties ¬
				{column count:(count of fieldNames) ¬
					, row count:(recordCount + 1) ¬
					, header row count:1 ¬
					, header column count:0}
		end tell
		tell thisTable
			set alignment of every column to center
			repeat with i from 1 to the count of fieldNames
				set the value of cell i of row 1 to (item i of fieldNames)
			end repeat
		end tell
	end tell
end tell

tell application "Database Events"
	tell database targetDatabaseFile
		repeat with i from 1 to the count of records
			tell record i
				set thisRecordData to (the value of fields 2 thru -1)
				tell application "Numbers"
					tell thisTable
						repeat with q from 1 to the count of thisRecordData
							set the value of cell q of row (i + 1) to ¬
								(item q of thisRecordData)
						end repeat
					end tell
				end tell
			end tell
		end repeat
	end tell
end tell

tell application "Numbers"
	display dialog "Table has been created." buttons {"OK"} default button 1
end tell
