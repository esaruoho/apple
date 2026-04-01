tell application "Keynote"
	activate
	if not (exists front document) then error number -128
	display dialog "This script will delete every skipped slide of the frontmost presentation." & ¬
		return & return & ¬
		"Continue?" buttons {"Cancel", "Delete Slides"} default button 1 with icon 2
	tell the front document
		delete (every slide whose skipped is true)
	end tell
end tell
