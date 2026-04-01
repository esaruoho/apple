property target_dimensions : "1024, 768"

set this_file to choose file without invisibles
-- get the final dimensions for the padded image
repeat
	display dialog "Enter the target dimensions for the padded image:" & return & return & "target width, target height" default answer target_dimensions
	set the dimensions_string to the text returned of the result
	try
		if the dimensions_string does not contain "," then error
		set AppleScript's text item delimiters to ","
		copy every text item of the dimensions_string to {width_string, height_string}
		set AppleScript's text item delimiters to ""
		set target_W to width_string as integer
		set target_H to height_string as integer
		if target_W is less than 1 then error
		if target_H is less than 1 then error
		set the target_dimensions to (target_W & ", " & target_H) as string
		exit repeat
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
