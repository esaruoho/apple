on add_leading_zeros(this_number, max_leading_zeros)
	set the threshold_number to (10 ^ max_leading_zeros) as integer
	if this_number is less than the threshold_number then
		set the leading_zeros to ""
		set the digit_count to the length of ((this_number div 1) as string)
		set the character_count to (max_leading_zeros + 1) - digit_count
		repeat character_count times
			set the leading_zeros to (the leading_zeros & "0") as string
		end repeat
		return (leading_zeros & (this_number as text)) as string
	else
		return this_number as text
	end if
end add_leading_zeros
