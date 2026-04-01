on replace_matches(this_list, match_item, replacement_item, replace_all)
	repeat with i from 1 to the count of this_list
		set this_item to item i of this_list
		if this_item is the match_item then
			set item i of this_list to the replacement_item
			if replace_all is false then return this_list
		end if
	end repeat
	return this_list
end replace_matches
