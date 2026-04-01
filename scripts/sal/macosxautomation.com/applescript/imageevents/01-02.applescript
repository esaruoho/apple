set this_file to choose file
try
	tell application "Image Events"
		-- start the Image Events application
		launch
		-- open the image file
		set this_image to open this_file
		-- extract the properties record
		set the props_rec to the properties of this_image
		-- purge the open image data
		close this_image
		-- extract the property values from the record
		set the image_info to ""
		set the image_info to the image_info & "Name: " & (name of props_rec) & return
		set the image_info to the image_info & "File: " & (path of image file of props_rec) & return
		set the image_info to the image_info & "Location: " & (path of location of props_rec) & return
		set the image_info to the image_info & "File Type: " & (file type of props_rec) & return
		set the image_info to the image_info & "Bit Depth: " & (bit depth of props_rec) & return
		set the image_info to the image_info & "Res: " & item 1 of (resolution of props_rec) & return
		set the image_info to the image_info & "Color Space: " & (color space of props_rec) & return
		copy (dimensions of props_rec) to {x, y}
		set the image_info to the image_info & "Dimemsions: " & x & ", " & y
	end tell
	display dialog image_info
on error error_message
	display dialog error_message
end try
