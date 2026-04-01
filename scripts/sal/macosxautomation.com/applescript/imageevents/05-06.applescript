(* IMPORTANT: The with pad color parameter of the pad command does not work in Mac OS 10.5.5. Use4 the SIPS command-line utility instead when padding with a color *)

property target_dimensions : "1024, 768"
property default_color : {0, 0, 0}

set this_file to choose file with prompt "Pick an image to pad:" without invisibles
set this_path to the quoted form of the POSIX path of this_file

-- get the final dimensions for the padded image
repeat
	display dialog "Enter the target dimensions for the padded image:" & return & return & "target width, target height" default answer target_dimensions buttons {"Cancel", "Set Color", "Continue"} default button 3
	copy the result to {text returned:dimensions_string, button returned:button_pressed}
	if the button_pressed is "Set Color" then
		set the default_color to choose color default color default_color
	else
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
	end if
end repeat
set the hex_color to text 2 thru -1 of (my RBG_to_HTML(default_color))
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
		(* The with pad color parameter is broken in Mac OS X 10.5.5 
		-- perform action
		pad this_image to dimensions {target_W, target_H} with pad color default_color
		*)
		-- save the changes
		save this_image with icon
		-- purge the open image data
		close this_image
	end tell
	
	-- The with pad color parameter is not working in 10.5.5 so use the SIPS command-line utitlity instead
	do shell script "sips " & this_path & " -p " & target_H & space & target_W & space & "--padColor " & hex_color & space & "-i"
	
on error error_message
	display dialog error_message buttons {"Cancel"} default button 1
end try

on RBG_to_HTML(RGB_values)
	-- NOTE: this sub-routine expects the RBG values to be from 0 to 65535
	set the hex_list to {"0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F"}
	set the the hex_value to ""
	repeat with i from 1 to the count of the RGB_values
		set this_value to (item i of the RGB_values) div 256
		if this_value is 256 then set this_value to 255
		set x to item ((this_value div 16) + 1) of the hex_list
		set y to item (((this_value / 16 mod 1) * 16) + 1) of the hex_list
		set the hex_value to (the hex_value & x & y) as string
	end repeat
	return ("#" & the hex_value) as string
end RBG_to_HTML
