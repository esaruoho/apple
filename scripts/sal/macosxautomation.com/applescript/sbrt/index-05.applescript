set file_name to "RESTORATION.TXT"
display dialog "The name of the file is: " & return & return & file_name buttons {"OK"} default button 1
set file_name to remove_extension(file_name)
display dialog "The name of the file without the extension is: " & return & return & file_name buttons {"OK"} default button 1

on remove_extension(this_name)
	if this_name contains "." then
		set this_name to (the reverse of every character of this_name) as string
		set x to the offset of "." in this_name
		set this_name to (text (x + 1) thru -1 of this_name)
		set this_name to (the reverse of every character of this_name) as string
	end if
	return this_name
end remove_extension
