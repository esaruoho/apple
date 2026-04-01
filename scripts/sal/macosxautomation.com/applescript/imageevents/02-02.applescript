set this_file to choose file without invisibles
display dialog "Flip direction:" buttons {"Horizontal", "Vertical", "Both"}
set the flip_direction to the button returned of the result
try
	tell application "Image Events"
		-- start the Image Events application
		launch
		-- open the image file
		set this_image to open this_file
		-- perform the manipulation
		if the flip_direction is "Horizontal" then
			flip this_image with horizontal
		else if the flip_direction is "Vertical" then
			flip this_image with vertical
		else
			flip this_image with horizontal and vertical
		end if
		-- save the changes
		save this_image with icon
		-- purge the open image data
		close this_image
	end tell
on error error_message
	display dialog error_message
end try
