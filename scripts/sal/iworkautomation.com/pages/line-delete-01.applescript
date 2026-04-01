tell application "Pages"
	activate
	display dialog "Delete lines from the current page?" buttons {"Cancel", "Delete All", "Delete Unlocked"} default button 1
	set deletionOption to the button returned of the result
	tell document 1
		tell current page
			if deletionOption is "Delete All" then
				set locked of every line to false
				delete every line
			else
				delete (every line whose locked is false)
			end if
		end tell
	end tell
end tell
