set this_file to choose file without invisibles
set the target_file to (choose file name default name "newimage.tif")
-- convert file reference in alias format to path string
set the target_path to the target_file as Unicode text
try
	tell application "Image Events"
		-- start the Image Events application
		launch
		-- open the image file
		set this_image to open this_file
		-- save in new file
		save this_image as TIFF in target_path with icon
		-- purge the open image data
		close this_image
	end tell
on error error_message
	display dialog error_message buttons {"Cancel"} default button 1
end try
