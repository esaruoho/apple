on open location this_url
	-- When the link is clicked in thewebpage, this handler will be passed 
	-- the URL that triggered the action, similar to:
	--> yourURLProtocol://yourBundleIdentifier?key=value&key=value
	
	-- EXTRACT ARGUMENTS
	set x to the offset of "?" in this_url
	set the argument_string to text from (x + 1) to -1 of this_url
	set AppleScript's text item delimiters to "&"
	set these_arguments to every text item of the argument_string
	set AppleScript's text item delimiters to ""
	
	-- PROCESS ACTIONS
	-- This loop will execute scripts located within the Resources folder
	-- of this applet depending on the key and value passed in the URL
	repeat with i from 1 to the count of these_arguments
		set this_pair to item i of these_arguments
		set AppleScript's text item delimiters to "="
		copy every text item of this_pair to {this_key, this_value}
		set AppleScript's text item delimiters to ""
		if this_key is "action" then
			if this_value is "1" then
				if my run_scriptfile("Action Script 01.scpt") is false then error number -128
			else if this_value is "2" then
				if my run_scriptfile("Action Script 02.scpt") is false then error number -128
			else if this_value is "3" then
				if my run_scriptfile("Action Script 03.scpt") is false then error number -128
			end if
		end if
	end repeat
end open location

on run_scriptfile(this_scriptfile)
	-- This handler will execute a script file 
	-- located in the Resources folder of this applet
	try
		set the script_file to path to resource this_scriptfile
		return (run script script_file)
	on error
		return false
	end try
end run_scriptfile

on load_run(this_scriptfile, this_property_value)
	-- This handler will load, then execute, a script file 
	-- located in the Resources folder of this applet.
	-- This method allows you to change property values
	-- within the loaded script before execution,
	-- or to execute handlers within the loaded script.
	try
		set the script_file to path to resource this_scriptfile
		
		set this_script to load script script_file
		set main_property of this_script to this_property_value
		
		return (run script this_script)
	on error
		return false
	end try
end load_run
