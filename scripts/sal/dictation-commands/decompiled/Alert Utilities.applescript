on «event NYHYHONK» sourceText given «class DURA»:durationValue, «class HONK»:gooseHonkValue, «class ADVS»:advancedSettingsRecord
	
	-- GET THE POSIX PATH TO THE UTILITY IN THE BUNDLE RESOURCE FOLDER
	set the honkUtility to the quoted form of the POSIX path of (path to resource "BigHonkingText")
	
	-- CONSTRUCT THE COMMAND STRING
	set the commandString to honkUtility & space & (quoted form of the (space & sourceText & space))
	
	-- ADD THE REQUIRED PARAMETERS
	if durationValue is not missing value then
		set the durationValue to (durationValue as integer) as string
		set the commandSubstring to "-p" & space & durationValue
		-- APPEND TO THE COMMAND STRING
		set the commandString to commandString & space & commandSubstring
	end if
	
	if gooseHonkValue is not missing value then
		-- APPEND TO THE COMMAND STRING
		if gooseHonkValue is true then
			set the commandString to commandString & space & "-H"
		end if
	end if
	
	-- ADD THE ADVANCED PARAMETERS, IF ANY.
	if advancedSettingsRecord is not missing value then
		try -- will fail if the matching setting is not in the passed record
			set fontColorValue to the «class FCOL» of advancedSettingsRecord
			if fontColorValue is not missing value then
				if the class of fontColorValue is list then
					set fontColorValue to text 2 thru -1 of (my RBGtoHTML(fontColorValue))
				end if
				-- APPEND TO THE COMMAND STRING
				set the commandString to commandString & space & "-f" & space & fontColorValue
			end if
		end try
		
		try -- will fail if the matching setting is not in the passed record
			set backgroundColorValue to the «class BCOL» of advancedSettingsRecord
			if backgroundColorValue is not missing value then
				if the class of backgroundColorValue is list then
					set backgroundColorValue to text 2 thru -1 of (my RBGtoHTML(backgroundColorValue))
				end if
				-- APPEND TO THE COMMAND STRING
				set the commandString to commandString & space & "-b" & space & backgroundColorValue
			end if
		end try
		
		try -- will fail if the matching setting is not in the passed record
			set backgroundDimensions to the «class BDIM» of advancedSettingsRecord
			if backgroundDimensions is not missing value then
				-- EXTRACT WINDOW WIDTH AND HEIGHT
				copy backgroundDimensions to {windowWidth, windowHeight}
				set the commandSubstring to (("-w" & space & windowWidth) as string) & space & (("-h" & space & windowHeight) as string)
				-- APPEND TO THE COMMAND STRING
				set the commandString to commandString & space & commandSubstring
			end if
		end try
		
		try -- will fail if the matching setting is not in the passed record
			set backgroundPosition to the «class BPOS» of advancedSettingsRecord
			if backgroundPosition is not missing value then
				-- EXTRACT WINDOW LEFT AND BOTTOM
				copy backgroundPosition to {windowLeft, windowBottom}
				set the commandSubstring to (("-x" & space & windowLeft) as string) & space & (("-y" & space & windowBottom) as string)
				-- APPEND TO THE COMMAND STRING
				set the commandString to commandString & space & commandSubstring
			end if
		end try
		
		try -- will fail if the matching setting is not in the passed record
			set backgroundOpacity to the «class OPAC» of advancedSettingsRecord
			if backgroundOpacity is not missing value then
				if backgroundOpacity is greater than 100 then
					set backgroundOpacity to 100
				else if backgroundOpacity is less than 0 then
					set backgroundOpacity to 0
				end if
				set the opacityAsRealAsString to (the backgroundOpacity * 0.01) as string
				set the commandSubstring to "-o" & space & opacityAsRealAsString
				-- APPEND TO THE COMMAND STRING
				set the commandString to commandString & space & commandSubstring
			end if
		end try
	end if
	
	-- EXECUTE THE COMMAND
	do shell script commandString
	
end «event NYHYHONK»

on RBGtoHTML(RGB_values)
	-- NOTE: this sub-routine expects the RBG values to be from 0 to 65535
	set the hex_list to {"0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F"}
	set the the hex_value to ""
	repeat with i from 1 to the count of the RGB_values
		set this_value to (item i of the RGB_values) div 256
		if this_value is 256 then set this_value to 255
		set x to item ((this_value div 16) + 1) of the hex_list
		set y to item (((this_value / 16 mod 1) * 16) + 1) of the hex_list
		set the hex_value to (the hex_value & x & y) as string
	end repeat
	return ("#" & the hex_value) as string
end RBGtoHTML
