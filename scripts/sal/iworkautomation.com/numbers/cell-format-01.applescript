tell application "Numbers"
	activate
	if not (exists document 1) then error number -128
	tell document 1
		tell active sheet
			-- make a new table
			set thisTable to make new table with properties ¬
				{row count:16, column count:2, name:"Cell Formats"}
			tell thisTable
				-- a list of the supported formats
				set theseFormats to {automatic, checkbox, currency, date and time, fraction, number, percent, pop up menu, scientific, slider, stepper, text, duration, rating, numeral system}
				-- placeholder data
				set formatData to {"", true, 1234.02, (get current date), 0.1, 123.89, 0.75, "", 64, 64, 35, "HOWDY", 4.5, 3, 4569.123}
				-- set the values of the first column with the names of the formats
				tell column 1
					repeat with i from 1 to the count of theseFormats
						set the value of cell (i + 1) to (item i of theseFormats) as string
					end repeat
				end tell
				-- set the formats of the column cells, and add placeholder data
				tell column 2
					repeat with i from 1 to the count of theseFormats
						set the format of cell (i + 1) to (item i of theseFormats)
						set the value of cell (i + 1) to (item i of formatData)
					end repeat
				end tell
			end tell
		end tell
	end tell
end tell
