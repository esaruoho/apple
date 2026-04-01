property thisMasterSlideName : "Photo - 3 Up"

tell application "Keynote"
	activate
	tell document 1
		
		-- GET A LIST OF THE NAMES OF THE MASTER SLIDES OF A DOCUMENT
		set the masterSlideNames to the name of every master slide
		--> {"Title & Subtitle", "Photo - Horizontal", "Title - Center", "Photo - Vertical", "Title - Top", "Title & Bullets", "Title, Bullets & Photo", "Bullets", "Photo - 3 Up", "Quote", "Photo", "Blank"}
		
		-- IF THE MASTER SLIDE IS USED BY THE CURRENT THEME, 
		-- CREATE A NEW SLIDE WITH MASTER
		if thisMasterSlideName is in the masterSlideNames then
			set thisSlide to ¬
				make new slide with properties {base slide:master slide thisMasterSlideName}
		end if
	end tell
end tell
