tell application "Keynote"
	activate
	tell the front document
		set skipped of ¬
			(every slide where the object text of its default title item contains "2012") to true
	end tell
end tell
