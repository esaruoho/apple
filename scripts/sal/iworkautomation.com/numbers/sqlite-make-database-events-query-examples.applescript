set databaseFile to (POSIX path of (path to documents folder)) & "Databases/Presidents of the United States.dbev"

tell application "Database Events"
	tell database databaseFile
		get value of field "Last Name" of (every record whose value of field "Start Year" is greater than or equal to 1800 and value of field "Start Year" is less than or equal to 1900)
		--> {"Adams", "Arthur", "Buchanan", "Cleveland", "Cleveland", "Fillmore", "Garfield", "Grant", "Harrison", "Harrison", "Hayes", "Jackson", "Jefferson", "Johnson", "Lincoln", "Madison", "McKinley", "Monroe", "Pierce", "Polk", "Taylor", "Tyler", "Van Buren"}
		
		get value of field "Last Name" of (every record whose value of field "Party" is "Republican")
		--> {"Arthur", "Bush", "Bush", "Coolidge", "Eisenhower", "Ford", "Garfield", "Grant", "Harding", "Harrison", "Hayes", "Hoover", "Lincoln", "McKinley", "Nixon", "Reagan", "Roosevelt", "Taft"}
		
		get value of field "Last Name" of (every record whose value of field "Start Year" is greater than 1899)
		--> {"Bush", "Bush", "Carter", "Clinton", "Coolidge", "Eisenhower", "Ford", "Harding", "Hoover", "Johnson", "Kennedy", "Nixon", "Reagan", "Roosevelt", "Roosevelt", "Taft", "Truman", "Wilson"}
		
		get the first record whose value of field "Last Name" contains "Adams"
		--> record id 438049003 of database "Presidents of the United States"
		
		get the value of field "Last Name" of every record
		--> {"Adams", "Adams", "Arthur", "Buchanan", "Bush", "Bush", "Carter", "Cleveland", "Cleveland", "Clinton", "Coolidge", "Eisenhower", "Fillmore", "Ford", "Garfield", "Grant", "Harding", "Harrison", "Harrison", "Hayes", "Hoover", "Jackson", "Jefferson", "Johnson", "Johnson", "Kennedy", "Lincoln", "Madison", "McKinley", "Monroe", "Nixon", "Pierce", "Polk", "Reagan", "Roosevelt", "Roosevelt", "Taft", "Taylor", "Truman", "Tyler", "Van Buren", "Washington", "Wilson"}
		
		tell (first record whose value of field "Index" is 16)
			set dialogText to (value of field "First Name") & space & (value of field "Last Name")
			set dialogText to dialogText & linefeed & tab & "Index: " & (value of field "Index")
			set dialogText to dialogText & linefeed & tab & "Party: " & (value of field "Party")
			set dialogText to dialogText & linefeed & tab & "Served: " & (value of field "Start Year") & "-" & (value of field "End Year")
		end tell
	end tell
end tell

display dialog dialogText buttons {"OK"} default button 1
