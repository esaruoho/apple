tell application "Numbers"
	activate
	try
		-- get application template names
		set theseUserTemplateNames to ¬
			the name of every template whose id of it begins with "User/"
		
		-- check for installation of user template
		set thisUserTemplateName to "Official Corporate Template"
		if thisUserTemplateName is not in theseUserTemplateNames then
			-- notify user of missing resource
			set thisMessage to "The Numbers template “" & thisUserTemplateName & "” " & ¬
				"is not installed on this computer." & return & return & ¬
				"Download the template from the company webiste."
			display alert "MISSING TEMPLATE" message thisMessage ¬
				buttons {"Download", "Cancel"} default button 2
			if button returned of the result is "Download" then
				open location "https://mycompanyname.com/communications/templates"
			end if
		else
			-- create a default document, styled with the template
			make new document with properties ¬
				{document template:template thisUserTemplateName}
		end if
	on error errorMessage number errorNumber
		if errorNumber is not -128 then
			display alert ("ERROR " & errorNumber) as string message errorMessage
		end if
	end try
end tell
