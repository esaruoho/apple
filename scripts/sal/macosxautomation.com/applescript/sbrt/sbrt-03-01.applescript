on highest_number(values_list)
	set the high_amount to ""
	repeat with i from 1 to the count of the values_list
		set this_item to item i of the values_list
		set the item_class to the class of this_item
		if the item_class is in {integer, real} then
			if the high_amount is "" then
				set the high_amount to this_item
			else if this_item is greater than the high_amount then
				set the high_amount to item i of the values_list
			end if
		else if the item_class is list then
			set the high_value to highest_number(this_item)
			if the the high_value is greater than the high_amount then set the high_amount to the high_value
		end if
	end repeat
	return the high_amount
end highest_number
