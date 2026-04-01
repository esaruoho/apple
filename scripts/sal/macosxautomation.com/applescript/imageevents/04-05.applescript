set this_file to choose file without invisibles
set the target_length to 640
repeat
	display dialog "Enter the target length and choose the dimension of the image to scale to the target length:" default answer target_length buttons {"Cancel", "Height", "Width"}
	copy the result as list to {target_length, target_dimension}
	try
		set the target_length to the target_length as number
		if the target_length is greater than 0 then
			exit repeat
		else
			error
		end if
	on error
		beep
	end try
end repeat
try
	tell application "Image Events"
		-- start the Image Events application
		launch
		-- open the image file
		set this_image to open this_file
		-- get dimensions of the image
		copy dimensions of this_image to {W, H}
		-- determine scale length
		if the target_dimension is "Height" then
			if W is less than H then
				set the scale_length to the target_length
			else
				set the scale_length to (W * target_length) / H
				set the scale_length to round scale_length rounding as taught in school
			end if
		else -- target dimension is Width
			if W is less than H then
				set the scale_length to (H * target_length) / W
				set the scale_length to round scale_length rounding as taught in school
			else
				set the scale_length to the target_length
			end if
		end if
		-- perform action
		scale this_image to size scale_length
		-- save the changes
		save this_image with icon
		-- purge the open image data
		close this_image
	end tell
on error error_message
	display dialog error_message
end try
