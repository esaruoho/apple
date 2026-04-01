tell application "Finder"
	set the percent_free to (((the free space of the startup disk) / (the capacity of the startup disk)) * 100) div 1
end tell
if the percent_free is less than 10 then
	tell application (path to frontmost application as text)
		display dialog "The startup disk has only " & the percent_free & " percent of its capacity available." & return & return & "Should this script continue?" with icon 1
	end tell
end if
