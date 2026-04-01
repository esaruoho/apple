-- this sub-routine is used to decode text strings 
on decode_text(this_text)
	set flag_A to false
	set flag_B to false
	set temp_char to ""
	set the character_list to {}
	repeat with this_char in this_text
		set this_char to the contents of this_char
		if this_char is "%" then
			set flag_A to true
		else if flag_A is true then
			set the temp_char to this_char
			set flag_A to false
			set flag_B to true
		else if flag_B is true then
			set the end of the character_list to my decode_chars(("%" & temp_char & this_char) as string)
			set the temp_char to ""
			set flag_A to false
			set flag_B to false
		else
			set the end of the character_list to this_char
		end if
	end repeat
	return the character_list as string
end decode_text
