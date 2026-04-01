on round_truncate(this_number, decimal_places)
	if decimal_places is 0 then
		set this_number to this_number + 0.5
		return number_to_text(this_number div 1)
	end if
	
	set the rounding_value to "5"
	repeat decimal_places times
		set the rounding_value to "0" & the rounding_value
	end repeat
	set the rounding_value to ("." & the rounding_value) as number
	
	set this_number to this_number + rounding_value
	
	set the mod_value to "1"
	repeat decimal_places - 1 times
		set the mod_value to "0" & the mod_value
	end repeat
	set the mod_value to ("." & the mod_value) as number
	
	set second_part to (this_number mod 1) div the mod_value
	if the length of (the second_part as text) is less than the decimal_places then
		repeat decimal_places - (the length of (the second_part as text)) times
			set second_part to ("0" & second_part) as string
		end repeat
	end if
	
	set first_part to this_number div 1
	set first_part to number_to_text(first_part)
	set this_number to (first_part & "." & second_part)
	
	return this_number
end round_truncate
