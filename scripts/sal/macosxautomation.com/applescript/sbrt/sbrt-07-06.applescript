on insert_listitem(this_list, this_item, list_position)
	set the list_count to the count of this_list
	-- THE LIST POSITION INDICATES THE POSITION IN THE LIST 
	-- YOU WANT THE ADDED ITEM TO OCCUPY
	if the list_position is 0 then
		return false
	else if the list_position is less than 0 then
		if (the list_position * -1) is greater than the list_count + 1 then return false
	else
		if the list_position is greater than the list_count + 1 then return false
	end if
	if the list_position is less than 0 then
		if (the list_position * -1) is the list_count + 1 then
			set the beginning of this_list to this_item
		else
			set this_list to the reverse of this_list
			set the list_position to (list_position * -1)
			set this_list to (items 1 thru (list_position - 1) of this_list) & this_item & (items list_position thru -1 of this_list)
			set this_list to the reverse of this_list
		end if
	else
		if the list_position is 1 then
			set the beginning of this_list to this_item
		else if the list_position is (the list_count + 1) then
			set the end of this_list to this_item
		else
			set this_list to (items 1 thru (list_position - 1) of this_list) & this_item & (items list_position thru -1 of this_list)
		end if
	end if
	return this_list
end insert_listitem
