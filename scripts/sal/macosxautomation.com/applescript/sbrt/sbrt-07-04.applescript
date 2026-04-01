on list_positions(this_list, this_item, list_all)
	set the offset_list to {}
	repeat with i from 1 to the count of this_list
		if item i of this_list is this_item then
			set the end of the offset_list to i
			if list_all is false then return item 1 of offset_list
		end if
	end repeat
	if list_all is false and offset_list is {} then return 0
	return the offset_list
end list_positions
