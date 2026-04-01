tell application "Keynote"
	activate
	try
		-- get theme names
		set the themeNames to the name of every theme
		
		-- prompt user to pick a theme
		set thisThemeName to ¬
			(choose from list themeNames with prompt "Choose a theme:")
		if thisThemeName is false then error number -128
		
		-- convert resulting list into a string: {"Black"} to "Black"
		set thisThemeName to thisThemeName as string
		
		-- create a default document, styled with the chosen theme
		make new document with properties ¬
			{document theme:theme thisThemeName}
		
	on error errorMessage number errorNumber
		if errorNumber is not -128 then
			display alert "THEME ISSUE" message errorMessage
		end if
	end try
end tell
