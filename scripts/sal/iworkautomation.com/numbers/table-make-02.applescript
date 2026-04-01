set the columnCount to 4
set the rowCount to 6

tell application "Numbers"
	activate
	
	if not (exists document 1) then error number -128
	
	tell document 1
		tell active sheet
			set thisTable to make new table with properties {column count:columnCount, row count:rowCount}
		end tell
	end tell
end tell
