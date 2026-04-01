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
		
		-- MAKE NEW PRESENTATION
		set thisDocument to ¬
			make new document with properties ¬
				{document theme:theme thisThemeName, width:1920, height:1080}
		
		tell thisDocument
			-- FORMAT THE FIRST SLIDE
			set the base slide of the first slide to master slide "Title & Subtitle"
			tell the first slide
				set the object text of the default title item to "My Presentation"
				set the object text of the default body item to "Fun Stuff for You to Know"
			end tell
			
			-- ADD INFORMATION SLIDE
			set thisSlide to make new slide with properties ¬
				{base slide:master slide "Title & Bullets"}
			tell thisSlide
				set the object text of the default title item to "Main Point"
				set the object text of the default body item to ¬
					"Bullet Point 1" & return & "Bullet Point 2" & return & "Bullet Point 3"
			end tell
			
			-- ADD CLOSING SLIDE
			set thisSlide to make new slide with properties ¬
				{base slide:master slide "Title - Center"}
			tell thisSlide
				set the object text of the default title item to "Thank You!"
			end tell
			
		end tell
		
		-- PLAY THE PRESENTATION
		start thisDocument from the first slide of thisDocument
		
	on error errorMessage number errorNumber
		if errorNumber is not -128 then
			display alert ("ERROR " & errorNumber) message errorMessage
		end if
	end try
end tell
