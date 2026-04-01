set the columnCount to 4
set the rowCount to 6
set the tableName to "Project Costs"

tell application "Numbers"
	activate
	
	if not (exists document 1) then error number -128
	
	tell document 1
		set thisSheet to make new sheet
		tell thisSheet
			delete every table
			set thisTable to make new table with properties ¬
				{column count:columnCount, row count:rowCount, name:tableName}
		end tell
	end tell
end tell
