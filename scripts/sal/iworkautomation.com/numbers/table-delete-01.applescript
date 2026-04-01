tell application "Numbers"
	activate
	if not (exists document 1) then error number -128
	
	tell the front document
		delete (every table of every sheet whose name ends with "2012")
	end tell
end tell
