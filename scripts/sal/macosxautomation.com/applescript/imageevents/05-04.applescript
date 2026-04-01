set this_file to choose file without invisibles
-- indicate the final dimensions for the padded image
set target_W to 960
set target_H to 540
try
	tell application "Image Events"
		-- start the Image Events application
		launch
		-- open the image file
		set this_image to open this_file
		-- get dimensions of the image
		copy dimensions of this_image to {W, H}
		-- calculate scaling
		if target_W is greater than target_H then
			if W is greater than H then
				set the scale_length to (W * target_H) / H
				set the scale_length to round scale_length rounding as taught in school
			else
				set the scale_length to target_H
			end if
		else if target_H is greater than target_W then
			if H is greater than W then
				set the scale_length to (H * target_W) / W
				set the scale_length to round scale_length rounding as taught in school
			else
				set the scale_length to target_W
			end if
		else -- square pad area
			set the scale_length to target_H
		end if
		-- perform action
		scale this_image to size scale_length
		-- perform action
		pad this_image to dimensions {target_W, target_H}
		-- save the changes
		save this_image with icon
		-- purge the open image data
		close this_image
	end tell
on error error_message
	display dialog error_message
end try
