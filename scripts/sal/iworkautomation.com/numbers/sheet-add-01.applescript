set the monthNames to {"January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"}
set thisYearName to (year of (current date)) as string

tell application "Numbers"
	activate
	-- confirmation dialog
	display dialog "This script will create a new document containing a sheet, " & ¬
		"with a named table, for every month of the year." buttons ¬
		{"Cancel", "Continue"} default button 2 with icon 1
	-- make a new document
	set thisDocument to make new document
	-- create a sheet with a named table for every month
	tell thisDocument
		repeat with i from 1 to the count of the monthNames
			set thisMonthName to item i of the monthNames
			set thisTableName to thisMonthName & "-" & thisYearName
			if i is 1 then
				-- name the sheet
				set the name of sheet 1 to thisMonthName
				tell sheet 1
					-- delete default table and create new one
					delete every table
					make new table with properties {name:thisTableName}
				end tell
			else
				-- make a new sheet
				set thisSheet to ¬
					make new sheet with properties {name:thisMonthName}
				tell thisSheet
					-- delete default table and create new one
					delete every table
					make new table with properties {name:thisTableName}
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
