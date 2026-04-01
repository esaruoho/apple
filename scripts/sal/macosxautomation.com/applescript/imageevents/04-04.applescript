set this_file to choose file without invisibles
set the scale_percentage to 50
repeat
	display dialog "Enter the scale percentage:" default answer scale_percentage
	try
		set the scale_percentage to the text returned of the result as number
		if the scale_percentage is greater than 0 then
			set the scale_factor to the scale_percentage * 0.01
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
		-- perform action
		scale this_image by factor scale_factor
		-- save the changes
		save this_image with icon
		-- purge the open image data
		close this_image
	end tell
on error error_message
	display dialog error_message
end try
