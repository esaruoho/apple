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
			tell selectedTable
				if the (count of cells of selection range) is not 1 then ¬
					error number 1002
				
				set cellID to the name of item 1 of selection range
				
				if address of row of cell cellID is less than or equal to 2 or ¬
					address of column of cell cellID is 1 then error number 1003
				
				set taskName to the formatted value of cell 1 of row of cell cellID
				
				set sessionDate to the value of cell 1 of column of cell cellID
				set sessionTimeString to ¬
					the formatted value of cell 2 of column of cell cellID
				--> "08:45-13:00"
				
				set startHour to (word -4 of sessionTimeString) as integer
				set startMinute to (word -3 of sessionTimeString) as integer
				set endHour to (word -2 of sessionTimeString) as integer
				set endMinute to (word -1 of sessionTimeString) as integer
				
				copy sessionDate to startTime
				set hours of startTime to startHour
				set minutes of startTime to startMinute
				set seconds of startTime to 0
				
				copy sessionDate to endTime
				set hours of endTime to endHour
				set minutes of endTime to endMinute
				set seconds of endTime to 0
				
				tell current application
					set userName to long user name of (get system info)
					set firstName to word 1 of userName
				end tell
				set value of cell cellID to firstName
				set the background color of cell cellID to {38390, 64038, 22477}
			end tell
		end tell
		
		tell current application
			set calendarID to ¬
				(do shell script "defaults read com.apple.iCal CalDefaultCalendar")
		end tell
		
		tell application "Calendar"
			activate
			if calendarID is "UseLastSelectedAsDefaultCalendar" then
				set defaultCalendar to calendar 1
			else
				set defaultCalendar to first calendar whose uid is calendarID
			end if
			tell defaultCalendar
				set newEvent to make new event with properties ¬
					{summary:taskName, start date:startTime, end date:endTime}
			end tell
			show newEvent
		end tell
		
	on error errorMessage number errorNumber
		if errorNumber is 1000 then
			set alertString to (errorNumber as string) & space & "MISSING RESOURCE"
			set errorMessage to ¬
				"Please create or open a document before running this script."
		else if errorNumber is 1001 then
			set alertString to "SELECTION ERROR"
			set errorMessage to ¬
				"Please select a single cell in a table before running this script."
		else if errorNumber is 1002 then
			set alertString to "SELECTION ERROR"
			set errorMessage to ¬
				"Please select a single cell in the table before running this script."
		else if errorNumber is 1003 then
			set alertString to "SELECTION ERROR"
			set errorMessage to ¬
				"Please select a single cell in the table that is not in a row or column header."
		else
			set alertString to "EXECUTION ERROR"
		end if
		display alert alertString message errorMessage buttons {"Cancel"}
		error number -128
	end try
end tell
