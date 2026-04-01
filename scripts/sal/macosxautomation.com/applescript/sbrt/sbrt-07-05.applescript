on count_matches(this_list, this_item)
	set the match_counter to 0
	repeat with i from 1 to the count of this_list
		if item i of this_list is this_item then set the match_counter to the match_counter + 1
	end repeat
	return the match_counter
end count_matches
