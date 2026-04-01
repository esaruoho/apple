tell application "Pages"
	tell the front document
		tell the body text
			-- implicit use of the get verb:
			set thisWord to the first word of the third paragraph
			say thisWord
			--> "Alice"
			-- Explicit use of the get verb:
			set thisWord to get the first word of the third paragraph
			say thisWord
			--> "Alice"
		end tell
	end tell
end tell
