tell application "Keynote"
	activate
	if not (exists document 1) then error number -128
	tell front document
		set the currentSlide to the current slide
		set the newSlide to make new slide at after the currentSlide
	end tell
end tell
