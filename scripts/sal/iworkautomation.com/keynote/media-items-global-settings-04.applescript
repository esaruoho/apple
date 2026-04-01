tell application "Keynote"
	activate
	if not (exists document 1) then error number -128
	tell the front document
		set documentWidth to its width
		
		tell every movie of every slide
			-- unlock first so properties can be changed
			set locked to false
			-- change other properties
			set width to 720
			set reflection showing to true
			set reflection value to 80
			set repetition method to none
			set movie volume to 75
			set position to {(documentWidth - 720) div 2, 144}
			-- set locked property
			set locked to true
		end tell
	end tell
end tell
