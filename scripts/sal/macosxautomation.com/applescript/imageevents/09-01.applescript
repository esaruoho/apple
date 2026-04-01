set this_file to choose file without invisibles
try
	tell application "Image Events"
		-- start the Image Events application
		launch
		-- open the image file
		set this_image to open this_file
		-- extract the metadata values
		tell this_image
			repeat with i from 1 to the count of metadata tags
				try
					set this_tag to metadata tag i
					set the tag_name to the name of this_tag
					set the tag_value to the value of this_tag
					if i is 1 then
						set the tag_text to tag_name & ": " & tag_value
					else
						set the tag_text to the tag_text & return & tag_name & ": " & tag_value
					end if
				on error
					if the tag_name is "profile" then
						set the tag_text to the tag_text & return & tag_name & ": " & name of tag_value
					end if
				end try
			end repeat
		end tell
		-- purge the open image data
		close this_image
	end tell
	display dialog tag_text
on error error_message
	display dialog error_message buttons {"Cancel"} default button 1
end try
