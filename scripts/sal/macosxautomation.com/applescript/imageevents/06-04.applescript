(* IMPORTANT: The with pad color parameter of the pad command does not work in Mac OS 10.5.5. Use4 the SIPS command-line utility instead when padding with a color *)
property default_color : {0, 0, 0}
property frame_TH : 12

set this_file to choose file with prompt "Pick an image to frame:" without invisibles
set this_path to the quoted form of the POSIX path of this_file

set the default_color to choose color default color default_color
set the hex_color to text 2 thru -1 of (my RBG_to_HTML(default_color))

try
	tell application "Image Events"
		-- start the Image Events application
		launch
		-- open the image file
		set this_image to open this_file
		-- get dimensions of the image
		copy dimensions of this_image to {W, H}
		(* The with pad color parameter is broken in Mac OS X 10.5.5 
		-- perform action
		pad this_image to dimensions {W + frame_TH, H + frame_TH}
		-- save the changes
		save this_image with icon
		*)
		-- purge the open image data
		close this_image
	end tell
	
	-- The with pad color parameter is not working in 10.5.5 so use the SIPS command-line utitlity instead
	set pad_H to (H + frame_TH) as integer as string
	set pad_W to (W + frame_TH) as integer as string
	do shell script "sips " & this_path & " -p " & pad_H & space & pad_W & space & "--padColor " & hex_color & space & "-i"
	
on error error_message
	display dialog error_message
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
