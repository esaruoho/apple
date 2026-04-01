tell application "Pages"
	activate
	tell the front document
		tell body text
			set the color of ¬
				(every word of every paragraph where it is "Alice") to {0, 0, 65535}
		end tell
	end tell
end tell
