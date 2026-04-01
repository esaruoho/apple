try
	--YOUR SCRIPT STATEMENTS GOE HERE 
on error error_message number error_number
	set this_error to "Error: " & error_number & ". " & error_message & return
	-- change the following line to the name and location desired 
	set the log_file to ((path to desktop) as string) & "Script Error Log"
	my write_to_file(this_error, log_file, true)
end try
