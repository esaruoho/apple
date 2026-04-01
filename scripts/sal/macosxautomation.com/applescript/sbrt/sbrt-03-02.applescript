on lowest_number(values_list)
	set the low_amount to ""
	repeat with i from 1 to the count of the values_list
		set this_item to item i of the values_list
		set the item_class to the class of this_item
		if the item_class is in {integer, real} then
			if the low_amount is "" then
				set the low_amount to this_item
			else if this_item is less than the low_amount then
				set the low_amount to item i of the values_list
			end if
		else if the item_class is list then
			set the low_value to lowest_number(this_item)
			if the the low_value is less than the low_amount then set the low_amount to the low_value
		end if
	end repeat
	return the low_amount
end lowest_number
