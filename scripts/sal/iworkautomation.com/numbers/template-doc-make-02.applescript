tell application "Numbers"
	activate
	try
		-- get application template names
		set theseApplicationTemplateNames to ¬
			the name of every template whose id of it begins with "Application/"
		
		-- prompt user to pick a template
		set thisTemplateName to ¬
			(choose from list theseApplicationTemplateNames with prompt "Choose a template:")
		if thisTemplateName is false then error number -128
		
		-- convert resulting list into a string: {"Black"} to "Black"
		set thisTemplateName to thisTemplateName as string
		
		-- create a default document, styled with the chosen template
		make new document with properties ¬
			{document template:template thisTemplateName}
		
	on error errorMessage number errorNumber
		if errorNumber is not -128 then
			display alert "TEMPLATE ISSUE" message errorMessage
		end if
	end try
end tell
