copy my deriveNameIndexLengthYearOfCurrentMonth() to ¬
	{thisMonthName, thisMonthIndex, monthLengthInDays, thisYearName}

tell application "Numbers"
	activate
	-- confirmation dialog
	display dialog "This script will create a new document " & ¬
		"containing a sheet for every day of the month." buttons ¬
		{"Cancel", "Continue"} default button 2 with icon 1
	-- make a new document
	set thisDocument to make new document
	-- create a sheet with a named table for every month
	tell thisDocument
		repeat with i from 1 to monthLengthInDays
			set the sheetName to ¬
				(thisMonthName & space & i & space & thisYearName) as string
			set the tableName to ¬
				(thisMonthIndex & "-" & i & "-" & thisYearName) as string
			if i is 1 then
				-- name the sheet
				set the name of sheet 1 to the sheetName
				-- delete default table and create new one
				tell sheet 1
					delete every table
					make new table with properties {name:tableName}
				end tell
			else
				-- make a new sheet
				set thisSheet to ¬
					make new sheet with properties {name:the sheetName}
				tell thisSheet
					-- delete default table and create new one
					delete every table
					make new table with properties {name:tableName}
				end tell
			end if
		end repeat
		delay 0.5
		-- display the first sheet by selecting table on current sheet, then table on first sheet
		set selection range of table 1 of sheet 12 to cell range of table 1 of sheet 12
		delay 1
		set selection range of table 1 of sheet 1 to cell range of table 1 of sheet 1
	end tell
	display dialog "Document created." buttons {"OK"} default button 1 with icon 1
end tell

on deriveNameIndexLengthYearOfCurrentMonth()
	set thisDate to (current date)
	set day of thisDate to 1
	set thisMonth to month of thisDate
	set thisMonthName to thisMonth as string
	set thisMonthIndex to thisMonth as integer
	set thisYearName to (year of thisDate) as string
	repeat with i from 1 to 32
		set thisDate to thisDate + (1 * days)
		if month of thisDate is not thisMonth then
			set monthLengthInDays to i
			exit repeat
		end if
	end repeat
	return {thisMonthName, thisMonthIndex, monthLengthInDays, thisYearName}
end deriveNameIndexLengthYearOfCurrentMonth
