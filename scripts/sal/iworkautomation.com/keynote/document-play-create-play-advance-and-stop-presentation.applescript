tell application "Keynote"
	activate
	
	set thisDocument to ¬
		make new document with properties ¬
			{document theme:theme "Black", width:1024, height:768}
	
	tell thisDocument
		set thisMasterSlide to master slide "Title - Center"
		tell the first slide
			set the base slide to thisMasterSlide
			set the object text of the default title item to "HELLO"
		end tell
		set thisSlide to ¬
			make new slide with properties {base slide:thisMasterSlide}
		tell thisSlide
			set the object text of the default title item to "GOODBYE"
		end tell
	end tell
	
	-- begin presenting
	start thisDocument from the first slide of thisDocument
	delay 2
	-- show the next slide or build
	show next
	delay 2
	-- stop the presentation
	stop thisDocument
end tell
