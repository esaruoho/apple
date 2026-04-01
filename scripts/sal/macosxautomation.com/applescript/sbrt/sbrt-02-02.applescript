on comma_delimit(this_number)
	set this_number to this_number as string
	if this_number contains "E" then set this_number to number_to_text(this_number)
	set the num_length to the length of this_number
	set the this_number to (the reverse of every character of this_number) as string
	set the new_num to ""
	repeat with i from 1 to the num_length
		if i is the num_length or (i mod 3) is not 0 then
			set the new_num to (character i of this_number & the new_num) as string
		else
			set the new_num to ("," & character i of this_number & the new_num) as string
		end if
	end repeat
	return the new_num
end comma_delimit
