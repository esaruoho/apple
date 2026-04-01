tell application "Keynote"
	activate
	try
		if not (exists document 1) then error number -128
		
		tell document 1
			
			set the base slide of the current slide to master slide "Title - Center"
			
		end tell
	on error errorMessage number errorNumber
		if errorNumber is not -128 then
			display alert ("ERROR " & errorNumber) message errorMessage
		end if
	end try
end tell
