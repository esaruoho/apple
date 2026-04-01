on add_numeric_suffix(this_num)
	set this_num to this_num as string
	if this_num ends with "11" or this_num ends with "12" or this_num ends with "13" then
		set the list_index to 1
	else
		set the list_index to (this_num mod 10) + 1
	end if
	set the num_suffix to item list_index of {"th", "st", "nd", "rd", "th", "th", "th", "th", "th", "th"}
	return (this_num & num_suffix)
end add_numeric_suffix
