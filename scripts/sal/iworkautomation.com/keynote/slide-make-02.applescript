tell application "Keynote"
	activate
	if not (exists document 1) then error number -128
	tell front document
		set the newSlide to make new slide at beginning of slides
	end tell
end tell
