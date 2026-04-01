tell application "Pages"
	activate
	tell the front document
		set thisCharacter to ¬
			a reference to the 1st character of the 1st paragraph of the body text
		tell thisCharacter
			set size to ((its size) * 3)
			set font to "Zapfino"
			set color of it to {0, 0, 65535}
		end tell
	end tell
end tell
