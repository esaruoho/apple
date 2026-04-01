try
	tell application id "com.apple.iWork.Numbers"
		activate
		
		if not (exists document 1) then error number 1000
		
		display dialog "This script will create a new table for tracking " & ¬
			"the attendance of the people in a chosen Contacts group." & ¬
			return & return & ¬
			"Should the table include Saturdays and Sundays?" buttons ¬
			{"Cancel", "Omit Weekends", "Include Weekends"} default button 3
		if the button returned of the result is "Include Weekends" then
			set includeWeekends to true
		else
			set includeWeekends to false
		end if
	end tell
	
	-- launch Contacts if not open
	if application id "com.apple.AddressBook" is not running then
		set AddressBookWasOpen to false
		tell application id "com.apple.AddressBook" to launch
	else
		set AddressBookWasOpen to true
	end if
	
	-- get the name of every group
	tell application id "com.apple.AddressBook"
		set the AddressBookGroupNames to the name of every group
	end tell
	if the AddressBookGroupNames is {} then error number 1001
	
	-- prompt user to pick group
	tell application id "com.apple.iWork.Numbers"
		activate
		set the chosenGroup to ¬
			(choose from list the AddressBookGroupNames ¬
				with prompt "Pick the Contacts group to be used for the table:")
		if the chosenGroup is false then error number -128
		set the chosenGroup to the chosenGroup as string
	end tell
	
	-- extract the full names of the group's people
	tell application id "com.apple.AddressBook"
		set thesePeople to every person of group chosenGroup
		if thesePeople is {} then error number 1002
		set the fullNames to {}
		repeat with i from 1 to the count of thesePeople
			set thisPerson to item i of thesePeople
			set the end of the fullNames to ¬
				(last name of thisPerson) & ", " & (first name of thisPerson)
		end repeat
		set the peopleCount to the count of the fullNames
	end tell
	
	-- close Contacts if it wasn’t previously open
	if AddressBookWasOpen is false then
		tell application id "com.apple.AddressBook" to quit
	end if
	
	-- generate the column titles
	set tempDate to the current date
	set the columnTitles to {}
	set day of tempDate to 1
	set thisMonth to the month of tempDate
	repeat until month of tempDate is not thisMonth
		set thisDay to day of tempDate
		set thisWeekday to the (weekday of tempDate) as string
		if includeWeekends is true or (includeWeekends is false and ¬
			thisWeekday is not in {"Saturday", "Sunday"}) then
			set the dayTitle to ¬
				(thisDay & "-" & (text 1 thru 1 of thisWeekday)) as string
			set the end of the columnTitles to the dayTitle
		end if
		set tempDate to tempDate + (1 * days)
	end repeat
	
	set the dayCount to the count of the columnTitles
	
	set the tableName to chosenGroup & space & ¬
		(text 1 thru 3 of (thisMonth as string) & ¬
			"-" & year of (the current date)) as string
	set tableName to my incrementTableNameIfNeeded(tableName, "-")
	
	tell application id "com.apple.iWork.Numbers"
		activate
		
		tell document 1
			tell the active sheet
				
				-- make and populate the table
				-- include extra column for total of missed days
				set thisTable to make new table with properties ¬
					{column count:dayCount + 2, row count:peopleCount + 1, name:tableName}
				
				tell thisTable
					-- set any global cell properties
					set the height of every row to 24
					set the vertical alignment of every row to center
					set the alignment of every row to center
					-- insert data
					tell row 1
						-- set specific properties for the title row
						set the vertical alignment to center
						set the alignment to center
						-- insert column titles
						repeat with i from 2 to dayCount + 1
							set value of cell i to item (i - 1) of the columnTitles
						end repeat
					end tell
					tell column 1
						-- set specific properties for the title column
						set the vertical alignment to center
						set the alignment to left
						set width to 128
						-- insert full names
						repeat with i from 2 to peopleCount + 1
							set value of cell i to item (i - 1) of the fullNames
						end repeat
					end tell
					tell columns 2 thru -2
						set width to 36
					end tell
					
					-- get the range of the cells to set
					set the rangeStart to the name of cell 2 of column 2
					set the rangeEnd to the name of last cell of column -2
					-- set format of cells
					tell range (rangeStart & ":" & rangeEnd)
						set format to checkbox
					end tell
					
					-- Set the style and formula of the total missed days column
					tell last column
						set width to 60
						set the value of cell 1 to "MISSED"
						set alignment to center
					end tell
					repeat with i from 2 to the count of rows
						tell row i
							set the rangeString to (name of cell 2 & ":" & name of cell -2)
							set the formulaString to "=COUNTIF(" & rangeString & ", FALSE)"
							set the value of the last cell to formulaString
						end tell
					end repeat
					
					-- sort the table based on student names
					sort by column 1 direction ascending
				end tell
			end tell
		end tell
		return thisTable
	end tell
on error errorMessage number errorNumber
	if errorNumber is 1000 then
		set alertString to "MISSING NUMBERS RESOURCE"
		set errorMessage to "Please create or open a document before running this script."
	else if errorNumber is 1001 then
		set alertString to "MISSING CONTACTS RESOURCE"
		set errorMessage to "There are no groups in your Contacts."
	else if errorNumber is 1002 then
		set alertString to "MISSING CONTACTS RESOURCE"
		set errorMessage to "There are no people in the chosen Contacts group."
	else
		set alertString to "EXECUTION ERROR"
	end if
	if the errorNumber is not -128 then
		tell application id "com.apple.iWork.Numbers"
			activate
			display alert alertString message errorMessage buttons {"Cancel"}
			error number -128
		end tell
	end if
end try

on incrementTableNameIfNeeded(thisTableName, thisDivider)
	-- a routine for deriving a unique table name based on a provided table name
	tell application "Numbers"
		tell the front document
			tell the active sheet
				-- get a list of the names of the tables on the active sheet
				set the theseTableNames to the name of every table
				set the testTableName to the thisTableName
				set incrementor to 0
				-- increment the passed name, if needed
				repeat until testTableName is not in theseTableNames
					set incrementor to incrementor + 1
					set the testTableName to ¬
						thisTableName & thisDivider & (incrementor as string)
				end repeat
				-- return the non-conflicting table name
				return the testTableName
			end tell
		end tell
	end tell
end incrementTableNameIfNeeded
