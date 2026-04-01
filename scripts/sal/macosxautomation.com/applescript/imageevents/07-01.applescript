set this_file to choose file without invisibles
set the crop_W to 640
set the crop_H to 480
try
	tell application "Image Events"
		-- start the Image Events application
		launch
		-- open the image file
		set this_image to open this_file
		-- perform action
		crop this_image to dimensions {crop_W, crop_H}
		-- save the changes
		save this_image with icon
		-- purge the open image data
		close this_image
	end tell
on error error_message
	display dialog error_message buttons {"Cancel"} default button 1
end try
