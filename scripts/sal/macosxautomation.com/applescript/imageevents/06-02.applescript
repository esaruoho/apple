property points_per_inch : 72

set this_file to choose file without invisibles
set the frame_TH to 12 -- points, NOT pixels
try
	tell application "Image Events"
		-- start the Image Events application
		launch
		-- open the image file
		set this_image to open this_file
		-- get resolution of the image
		copy resolution of this_image to {X_res, Y_res}
		-- calculate the frame thickness based on points per inch
		set pixels_per_point to X_res / points_per_inch
		set the frame_TH to frame_TH * pixels_per_point
		set the frame_TH to round frame_TH rounding as taught in school
		-- get dimensions of the image
		copy dimensions of this_image to {W, H}
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
