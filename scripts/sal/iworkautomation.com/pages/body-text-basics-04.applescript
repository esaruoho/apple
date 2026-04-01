tell application "Pages"
	tell the front document
		tell the body text
			set thisWord to a reference to the first word of the third paragraph
			return thisWord
		end tell
	end tell
end tell
