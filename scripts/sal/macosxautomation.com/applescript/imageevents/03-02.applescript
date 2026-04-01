set this_file to choose file without invisibles
set the rotation_angle to 90
repeat
	display dialog "Enter the rotation angle:" default answer rotation_angle buttons {"Cancel", "Counter-Clockwise", "Clockwise"}
	copy the result as list to {rotation_angle, rotation_direction}
	try
		set rotation_angle to rotation_angle as number
		if the rotation_angle is greater than 0 and the rotation_angle is less than 360 then
			if the rotation_direction is "Counter-Clockwise" then
				set the rotation_angle to 360 - the rotation_angle
			end if
			exit repeat
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
		-- perform action
		rotate this_image to angle rotation_angle
		-- save the changes
		save this_image with icon
		-- purge the open image data
		close this_image
	end tell
on error error_message
	display dialog error_message
end try
