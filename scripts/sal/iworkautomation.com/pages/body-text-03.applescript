tell application "Pages"
	tell front document
		-- stop if the document does not contain a default text flow
		if document body is false then error number -128
		-- set the color of the document body text
		set the color of body text to {0, 0, 0}
		-- set the color of a page body text
		set the color of body text of the last page of the first section to {65535, 0, 0}
	end tell
end tell
