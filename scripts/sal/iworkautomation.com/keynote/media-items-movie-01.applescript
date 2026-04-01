tell application "Keynote"
	activate
	
	try
		-- PROMPT USER TO PICK MOVIE FILE
		set movieFileHFSAlias to ¬
			(choose file of type "public.movie" with prompt ¬
				"Select the movie file to import:" default location (path to movies folder))
		
		-- CREATE DOCUMENT IF ONE DOES NOT EXIST
		if not (exists document 1) then
			make new document with properties ¬
				{document theme:theme "Black", width:1024, height:768}
		end if
		
		tell document 1
			-- get document dimensions
			set docWidth to the width
			set docHeight to the height
			
			-- IMPORT MOVIE FILE TO CURRENT SLIDE
			tell the current slide
				-- Keynote does not support using the movie class with the make verb
				-- Import the movie file by using the image class as the direct parameter
				-- The returned object reference will be to the created movie item
				set thisMovie to make new image with properties {file:movieFileHFSAlias}
				--> movie 1 of slide 1 of document "Document Name"
				
				-- ADJUST MOVIE PROPERTIES
				tell thisMovie
					-- adjust the size and position of the movie item...
					-- using properties inherited from iWork Item class
					set movWidth to 720
					set width to movWidth
					set movHeight to height
					set position to ¬
						{(docWidth - movWidth) div 2, (docHeight - movHeight) div 2}
					-- movie class properties
					set reflection showing to true
					set reflection value to 75
					set movie volume to 90
					set repetition method to none
					-- place the locked property at the end because
					-- you can't change the properties of a locked iWork item
					set locked to true
				end tell
			end tell
		end tell
	on error errorMessage number errorNumber
		if errorNumber is not -128 then
			display alert ("ERROR " & errorNumber as string) message errorMessage
		end if
	end try
end tell
