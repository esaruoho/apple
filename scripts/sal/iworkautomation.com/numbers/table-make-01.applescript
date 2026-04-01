tell application "Numbers"
	activate
	
	if not (exists document 1) then error number -128
	
	tell the front document
		tell active sheet
			set thisTable to make new table
		end tell
	end tell
end tell
