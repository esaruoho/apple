tell application "Keynote"
	activate
	if not (exists document 1) then error number -128
	tell front document
		make new slide at before the last slide
		make new slide at after the second slide
		make new slide at after slide 3
		make new slide at before (the first slide whose skipped is true)
	end tell
end tell
