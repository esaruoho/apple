tell application "Numbers"
	activate
	try
		-- PROMPT USER TO PICK AUDIO CLIP FILE
		set audioFileHFSAlias to ¬
			(choose file of type "public.audio" with prompt ¬
				"Select the audio clip file to import:" default location (path to music folder))
		
		-- CREATE DOCUMENT IF ONE DOES NOT EXIST
		if not (exists document 1) then
			make new document with properties ¬
				{document template:template "Blank"}
		end if
		
		tell document 1
			-- IMPORT MOVIE FILE TO ACTIVE SHEET
			tell the active sheet
				-- Numbers does not support using the audio clip class with the make verb
				-- Import the audio clip file by using the image class as the direct parameter
				-- The returned object reference will be to the created audio clip item
				set thisAudioClip to make new image with properties {file:audioFileHFSAlias}
				--> audio clip 1 of sheet 1 of document "Document Name"
				
				-- ADJUST MOVIE PROPERTIES
				tell thisAudioClip
					-- adjust the size and position of the movie item...
					-- using properties inherited from iWork Item class
					set position to {0, 0}
					-- audio file class properties
					set clip volume to 90
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
