tell application "Keynote"
	activate
	repeat with i from (count of documents) to 1 by -1
		set thisDocument to document i
		if file of thisDocument is missing value then
			close thisDocument without saving
		end if
	end repeat
end tell
