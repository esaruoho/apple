tell application "Numbers"
	activate
	-- create a new document and store its reference in a variable
	set thisDocument to make new document
	-- address the document reference
	tell thisDocument
		-- remove any default tables
		delete every table of every sheet
	end tell
end tell
