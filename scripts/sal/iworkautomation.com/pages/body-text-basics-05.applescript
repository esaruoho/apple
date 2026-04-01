tell application "Pages"
	activate
	tell the front document
		tell body text
			
			-- tell statement (single sentence):
			tell the first character to set its color to "blue"
			
			-- tell block (begin tell and end tell)
			tell the first character
				set the color of it to "blue"
				set the size to "24"
				set the font to "Times New Roman Italic"
			end tell
			
		end tell
	end tell
end tell
