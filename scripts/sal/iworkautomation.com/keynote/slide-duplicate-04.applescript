tell application "Keynote"
	activate
	tell front document
		duplicate (slides 1 thru 2) to after slide 2
	end tell
end tell
