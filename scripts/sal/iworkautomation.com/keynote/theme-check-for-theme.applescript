property thisThemeName : "Black"

tell application "Keynote"
	activate
	try
		-- GET THE THEME NAMES
		set the themeNames to the name of every theme
		
		-- CHECK FOR THEME
		if thisThemeName is not in the themeNames then
			error "The theme “" & thisThemeName & "” is not installed on this computer."
		end if
		
	on error errorMessage number errorNumber
		if errorNumber is not -128 then
			display alert ("ERROR " & errorNumber) message errorMessage
		end if
	end try
end tell
