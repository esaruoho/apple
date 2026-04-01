set this_file to choose file without invisibles
set the TH_factor to 0.05 -- 5%
try
	tell application "Image Events"
		-- start the Image Events application
		launch
		-- open the image file
		set this_image to open this_file
		-- get dimensions of the image
		copy dimensions of this_image to {W, H}
		-- determine the length of the hypotenuse
		set the HY_length to ((W ^ 2) + (H ^ 2)) ^ 0.5
		-- determine the frame thickness
		set frame_TH to HY_length * TH_factor
		-- perform action
		pad this_image to dimensions {W + frame_TH, H + frame_TH}
		-- save the changes
		save this_image with icon
		-- purge the open image data
		close this_image
	end tell
on error error_message
	display dialog error_message
end try
