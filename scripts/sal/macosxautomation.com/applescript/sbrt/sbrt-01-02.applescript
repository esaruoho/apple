repeat
	display dialog "Enter an even integer:" default answer ""
	try
		if the text returned of the result is not "" then set the requested_number to the text returned of the result as integer
		if is_odd(the requested_number) is false then exit repeat
	end try
end repeat

on is_odd(this_number)
	if this_number mod 2 is not 0 then
		return true
	else
		return false
	end if
end is_odd
