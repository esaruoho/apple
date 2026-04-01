tell application "Keynote"
	activate
	tell document 1
		tell current slide
			try
				delete every line
			end try
		end tell
	end tell
end tell
