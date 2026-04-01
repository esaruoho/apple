tell application "Keynote"
	activate
	
	try
		-- PROMPT USER TO PICK AUDIO FILE
		set audioFileHFSAlias to ¬
			(choose file of type "public.audio" with prompt ¬
				"Select the audio file to import:" default location (path to music folder))
		
		-- CREATE DOCUMENT IF ONE DOES NOT EXIST
		if not (exists document 1) then
			make new document with properties ¬
				{document theme:theme "Black", width:1024, height:768}
		end if
		
		tell document 1
			-- IMPORT AUDIO FILE TO CURRENT SLIDE
			tell the current slide
				-- Keynote does not support using the audio clip class with the make verb
				-- Import the audio file by using the image class as the direct parameter
				-- The returned object reference will be to the created audio file
				set thisAudioClip to make new image with properties {file:audioFileHFSAlias}
				--> audio clip 1 of slide 1 of document "Document Name"
				
				-- ADJUST AUDIO CLIP PROPERTIES
				tell thisAudioClip
					-- position property inherited from iWork Item class
					set position to {48, 48}
					-- audio clip properties
					set clip volume to 75
					set repetition method to loop
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
