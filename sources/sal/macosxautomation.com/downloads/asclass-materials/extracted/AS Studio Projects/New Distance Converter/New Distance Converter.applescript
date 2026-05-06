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
				if the unit_type is "Miles" then
					set the temp_value to the input_amount as miles
				else if the unit_type is "Yards" then
					set the temp_value to the input_amount as yards
				else if the unit_type is "Feet" then
					set the temp_value to the input_amount as feet
				else if the unit_type is "Kilometers" then
					set the temp_value to the input_amount as kilometers
				else if the unit_type is "Meters" then
					set the temp_value to the input_amount as meters
				end if
				-- convert temp value to various unit types and display results
				set the contents of text field "miles readout" to (temp_value as miles) as real
				set the contents of text field "yards readout" to (temp_value as yards) as real
				set the contents of text field "feet readout" to (temp_value as feet) as real
				set the contents of text field "kilometers readout" to (temp_value as kilometers) as real
				set the contents of text field "meters readout" to (temp_value as meters) as real
			end tell
		on error
			display dialog "Please enter a value in the input field." buttons {"Cancel"} default button 1 attached to window "main"
		end try
	end if
end action