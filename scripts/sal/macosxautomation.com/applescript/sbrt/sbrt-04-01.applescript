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
