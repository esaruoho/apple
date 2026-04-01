on remove_markup(this_text)
	set copy_flag to true
	set the clean_text to ""
	repeat with this_char in this_text
		set this_char to the contents of this_char
		if this_char is "<" then
			set the copy_flag to false
		else if this_char is ">" then
			set the copy_flag to true
		else if the copy_flag is true then
			set the clean_text to the clean_text & this_char as string
		end if
	end repeat
	return the clean_text
end remove_markup
