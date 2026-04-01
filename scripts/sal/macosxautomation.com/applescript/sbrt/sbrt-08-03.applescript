-- this sub-routine is used to decode a three-character hex string 
on decode_chars(these_chars)
	copy these_chars to {indentifying_char, multiplier_char, remainder_char}
	set the hex_list to "123456789ABCDEF"
	if the multiplier_char is in "ABCDEF" then
		set the multiplier_amt to the offset of the multiplier_char in the hex_list
	else
		set the multiplier_amt to the multiplier_char as integer
	end if
	if the remainder_char is in "ABCDEF" then
		set the remainder_amt to the offset of the remainder_char in the hex_list
	else
		set the remainder_amt to the remainder_char as integer
	end if
	set the ASCII_num to (multiplier_amt * 16) + remainder_amt
	return (ASCII character ASCII_num)
end decode_chars
