space_check(20)

tell application "Finder"
	display dialog "This script will backup every document file in the top-level of your Documents folder to a folder on the desktop named EXAMPLE BACKUP." & return & return & "Continue?"
	if not (exists folder "EXAMPLE BACKUP") then
		make new folder at desktop with properties {name:"EXAMPLE BACKUP"}
	end if
	try
		repeat with this_file in (every document file of folder "Documents" of home)
			duplicate this_file to folder "EXAMPLE BACKUP" with replacing
			my space_check(20)
		end repeat
	on error error_message number error_number
		if the error_number is not -128 then
			display dialog error_message buttons {"OK"} default button 1
		end if
	end try
end tell

on space_check(threshold_percentage)
	tell application "Finder"
		set the percent_free to (((the free space of the startup disk) / (the capacity of the startup disk)) * 100) div 1
	end tell
	if the percent_free is less than the threshold_percentage then
		tell application (path to frontmost application as text)
			display dialog "The startup disk has only " & the percent_free & " percent of its capacity available." & return & return & "Should this script continue?" with icon 1
		end tell
	end if
end space_check
