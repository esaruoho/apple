set this_file to choose file without invisibles
try
	tell application "Image Events"
		-- start the Image Events application
		launch
		-- open the image file
		set this_image to open this_file
		-- extract the value for the metadata tag
		tell this_image
			set the camera_type to the value of metadata tag "model"
		end tell
		-- purge the open image data
		close this_image
	end tell
	display dialog camera_type
on error error_message
	display dialog error_message buttons {"Cancel"} default button 1
end try
