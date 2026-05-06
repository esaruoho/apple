tell application "Adobe InDesign CS2"
	activate
	tell the active document
		try
			set the_list to Â
				every text frame of every spread whose label is not ""
		on error
			error "There are no tagged text frames."
		end try
	end tell
	repeat with i from 1 to the number of items in the_list
		set this_frame to item i of the_list
		tell the active document
			set this_identifier to the label of this_frame
		end tell
		tell application "FileMaker Pro"
			activate
			tell database 1
				show (the first record whose cell "MLS Number" contains this_identifier)
				set the_data to cell "Ad Text" of the current record
			end tell
		end tell
		tell the active document
			set the contents of this_frame to the_data
			tell this_frame
				tell paragraph 1
					set applied font to "Gill Sans"
					set font style to "Bold"
					set point size to 12.0
					set leading to 12.0
				end tell
				tell paragraph 2
					set space before to 0.167
					set applied font to "Gill Sans"
					set font style to "Light"
					set point size to 10.0
					set leading to 11.0
				end tell
				tell paragraph 3
					set space before to 0.167
					set applied font to "Gill Sans"
					set font style to "Regular"
					set point size to 10.0
					set leading to 12.0
				end tell
				tell paragraph 4
					set applied font to "Gill Sans"
					set font style to "Regular"
					set point size to 10.0
					set leading to 12.0
				end tell
			end tell
		end tell
	end repeat
end tell