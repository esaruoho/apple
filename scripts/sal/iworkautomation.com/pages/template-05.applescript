property thisTemplateName : "Company Newsletter"

tell application "Pages"
	activate
	try
		-- GET THE TEMPLATE NAMES
		set the templateNames to the name of every template
		
		-- CHECK FOR TEMPLATE
		if thisTemplateName is not in the templateNames then
			error "The template “" & thisTemplateName & "” is not installed on this computer."
		end if
		
	on error errorMessage number errorNumber
		if errorNumber is not -128 then
			display alert ("ERROR " & errorNumber) message errorMessage
		end if
	end try
end tell
