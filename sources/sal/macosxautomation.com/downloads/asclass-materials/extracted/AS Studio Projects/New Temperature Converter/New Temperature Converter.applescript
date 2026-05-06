-- Application.applescript

on action this_object
	set this_name to the name of this_object
	if this_name is in {"input value", "unit popup"} then
		try
			tell window "main"
				-- get input value and indicated unit type
				set the unit_type to title of button "unit popup"
				set the input_amount to the contents of text field "input value"
				-- convert the input value to the indicated unit type
				if the unit_type is "Fahrenheit" then
					set the temp_value to the input_amount as degrees Fahrenheit
				else if the unit_type is "Celsius" then
					set the temp_value to the input_amount as degrees Celsius
				else if the unit_type is "Kelvin" then
					set the temp_value to the input_amount as degrees Kelvin
				end if
				-- convert temp value to various unit types and display results
				set the contents of text field "fahrenheit readout" to (temp_value as degrees Fahrenheit) as real
				set the contents of text field "celsius readout" to (temp_value as degrees Celsius) as real
				set the contents of text field "kelvin readout" to (temp_value as degrees Kelvin) as real
			end tell
		on error
			display dialog "Please enter a value in the input field." buttons {"Cancel"} default button 1 attached to window "main"
		end try
	end if
end action