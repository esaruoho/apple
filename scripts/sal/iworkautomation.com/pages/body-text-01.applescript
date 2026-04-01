tell application "Pages"
	tell front document
		-- stop if the document does not contain a default text flow
		if document body is false then error number -128
		-- set the color of the document body text
		set the color of body text to {65535, 0, 0}
	end tell
end tell
