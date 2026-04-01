property matchString : "2012"

tell application "Keynote"
	activate
	if not (exists front document) then error number -128
	display dialog "This script will delete slides from the frontmost presentation." & ¬
		return & return & ¬
		"Continue?" buttons {"Cancel", "Delete Slides"} default button 1 with icon 2
	tell the front document
		delete (every slide where the object text of its default title item contains matchString)
	end tell
end tell
