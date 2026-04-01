tell application "Keynote"
	activate
	try
		set thisDocument to ¬
			make new document with properties {document theme:theme "Black", width:1024, height:768}
		
		tell thisDocument
			
			tell the first slide
				set the base slide to master slide "Title & Subtitle" of thisDocument
				set the transition properties to ¬
					{transition effect:doorway, transition duration:2.0, transition delay:1.5, automatic transition:true}
				set the object text of the default title item to "My Presentation"
				set the object text of the default body item to "Fun Stuff for You to Know"
			end tell
			
			set thisSlide to make new slide with properties {base slide:master slide "Title & Bullets"}
			tell thisSlide
				set transition properties to ¬
					{transition effect:dissolve, transition duration:2.0, transition delay:1.5, automatic transition:true}
				set the object text of the default title item to "Main Topic"
				set the object text of the default body item to ¬
					"Bullet Point 1" & return & "Bullet Point 2" & return & "Bullet Point 3"
			end tell
		end tell
		
		-- PLAY THE PRESENTATION
		start thisDocument from the first slide of thisDocument
		
	on error errorMessage number errorNumber
		if errorNumber is not -128 then
			display alert ("ERROR " & errorNumber) as string message errorMessage
		end if
	end try
end tell
