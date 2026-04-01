tell application "Pages"
	activate
	-- if there is no open document then stop the script
	if not (exists document 1) then error number -128
	
	tell front document
		-- stop if the document does not contain a default text flow
		if document body is false then error number -128
		
		-- CHANGE PROPERTIES OF THE DOCUMENT TEXT
		tell body text
			set the font to "Verdana"
		end tell
		
		-- CHANGE THE PROPERTIES OF THE TEXT OF EVERY SECTION
		tell body text of every section
			set the size to 12
			set the color of it to {13107, 13107, 13107}
			-- set the properties of the 1st paragraph of every section
			tell its first paragraph
				set the font to "Times New Roman Bold"
				set the size to 18
				set its color to {0, 0, 0}
			end tell
		end tell
		
		-- CHANGE THE PROPERTIES OF THE TEXT OF THE LAST PAGE OF A SECTION
		set the sectionCount to the count of sections
		repeat with i from the sectionCount to 1 by -1
			if i is sectionCount then
				set the color of the body text of the last page to {65535, 0, 0}
			else
				tell section i of it
					tell body text of the last page
						set the color of it to {65535, 0, 0}
					end tell
				end tell
			end if
		end repeat
	end tell
	
	-- notify the user
	display notification "Section formating completed." with title "Pages AppleScript"
end tell
