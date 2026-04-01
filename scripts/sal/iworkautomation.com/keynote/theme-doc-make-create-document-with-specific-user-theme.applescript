tell application id "com.apple.iWork.Keynote"
	activate
	try
		-- get application theme names
		set theseUserThemeNames to ¬
			the name of every theme whose id of it begins with "User/"
		
		-- check for installation of user theme
		set thisUserThemeName to "Official Corporate Theme"
		if thisUserThemeName is not in theseUserThemeNames then
			-- notify user of missing resource
			set thisMessage to "The Keynote theme “" & thisUserThemeName & "” " & ¬
				"is not installed on this computer." & return & return & ¬
				"Download the theme from the company webiste."
			display alert "MISSING THEME" message thisMessage ¬
				buttons {"Download", "Cancel"} default button 2
			if button returned of the result is "Download" then
				tell current application
					open location "https://mycompanyname.com/communications/templates"
				end tell
			end if
		else
			-- create a default document, styled with the theme
			make new document with properties ¬
				{document theme:theme thisUserThemeName}
		end if
	on error errorMessage number errorNumber
		if errorNumber is not -128 then
			display alert ("ERROR " & errorNumber) as string message errorMessage
		end if
	end try
end tell
