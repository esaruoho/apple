property defaultStepperValue : 1
property defaultSliderValue : 1
property defaultCheckboxValue : false
property defaultCurrencyValue : 0
property defaultNumberValue : 0
property defaultTextValue : ""
property defaultDateAndTime : missing value

tell application "Numbers"
	activate
	try
		if not (exists document 1) then error number 1000
		tell document 1
			try
				tell active sheet
					set the selectedTable to ¬
						(the first table whose class of selection range is range)
				end tell
			on error
				error number 1001
			end try
			set defaultDateAndTime to (current date)
			tell selectedTable
				set the cellCount to the count of cells of the selection range
				repeat with i from 1 to the cellCount
					tell cell i of the selection range
						if format is in {stepper} then
							set the value to defaultStepperValue
						else if format is in {slider} then
							set the value to defaultSliderValue
						else if format is in {checkbox} then
							set the value to defaultCheckboxValue
						else if format is in {currency} then
							set the value to defaultCurrencyValue
						else if format is in {date and time} then
							set the value to defaultDateAndTime
						else if format is in {number} then
							set the value to defaultNumberValue
						else if format is in {text} then
							set the value to defaultTextValue
						else
							try
								set the value to ""
							end try
						end if
					end tell
				end repeat
			end tell
		end tell
	on error errorMessage number errorNumber
		if errorNumber is 1000 then
			set alertString to "MISSING RESOURCE"
			set errorMessage to ¬
				"Please create or open a document before running this script."
		else if errorNumber is 1001 then
			set alertString to "SELECTION ERROR"
			set errorMessage to ¬
				"Please select a table before running this script."
		else
			set alertString to "EXECUTION ERROR"
		end if
		if errorNumber is not -128 then
			display alert alertString message errorMessage buttons {"Cancel"}
		end if
		error number -128
	end try
end tell
