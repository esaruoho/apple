tell application "Pages"
	tell the front document
		tell the body text
			-- BOTH STATMENTS RETURN THE SAME RESULT
			-- NOTE: by default in the iWork applicaitons, use of a text object reference not preceded with a verb (command) returns its contents
			
			-- explicit use of the get verb:
			get first word of the third paragraph
			
			-- implicit use of the get verb:
			the first word of the third paragraph
		end tell
	end tell
end tell
