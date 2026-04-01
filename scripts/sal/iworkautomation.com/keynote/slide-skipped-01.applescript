tell application "Keynote"
	activate
	if not (exists front document) then error number -128
	tell the front document
		set skipped of every slide to false
	end tell
end tell
