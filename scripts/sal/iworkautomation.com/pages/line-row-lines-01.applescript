property defaultVerticalMargin : 36
property defaultHorizontalMargin : 36
property defaultGutterHeight : 12
property defaultRowCount : 6

tell application "Pages"
	activate
	
	set chosenPageSize to (choose from list {"Cancel", "A3", "A4", "A5", "B5", "US Letter", "US Legal", "Tabloid"} with prompt "Pick the page size:")
	if chosenPageSize is false then error number -128
	set chosenPageSize to chosenPageSize as string
	if chosenPageSize is "A4" then
		set thisPageDimensions to {595, 842}
	else if chosenPageSize is "A3" then
		set thisPageDimensions to {842, 1191}
	else if chosenPageSize is "A5" then
		set thisPageDimensions to {420, 595}
	else if chosenPageSize is "B5" then
		set thisPageDimensions to {499, 709}
	else if chosenPageSize is "US Letter" then
		set thisPageDimensions to {612, 792}
	else if chosenPageSize is "US Legal" then
		set thisPageDimensions to {612, 1008}
	else if chosenPageSize is "Tabloid" then
		set thisPageDimensions to {792, 1224}
	end if
	copy thisPageDimensions to {documentWidth, documentHeight}
	
	set thisPrompt to "Enter the top margin height in pixels:"
	set verticalTopMarginHeight to my promptForIntegerValue(thisPrompt, 0, documentHeight div 2, defaultVerticalMargin)
	
	set thisPrompt to "Enter the bottom margin height in pixels:"
	set verticalBottomMarginHeight to my promptForIntegerValue(thisPrompt, 0, documentHeight div 2, defaultVerticalMargin)
	
	set thisPrompt to "Enter the left margin width in pixels:"
	set sideLeftMarginWidth to my promptForIntegerValue(thisPrompt, 0, documentHeight div 2, defaultHorizontalMargin)
	
	set thisPrompt to "Enter the right margin width in pixels:"
	set sideRightMarginWidth to my promptForIntegerValue(thisPrompt, 0, documentHeight div 2, defaultHorizontalMargin)
	
	set thisPrompt to "Enter the gutter height in pixels:"
	set gutterHeight to my promptForIntegerValue(thisPrompt, 0, 200, defaultGutterHeight)
	
	set thisPrompt to "Enter the row count:"
	set rowCount to my promptForIntegerValue(thisPrompt, 2, 50, defaultRowCount)
	
	set gutterCount to rowCount - 1
	
	set editableAreaHeight to documentHeight - verticalTopMarginHeight - verticalBottomMarginHeight
	
	set editableRowAreaHeight to editableAreaHeight - (gutterCount * gutterHeight)
	
	set editableSegmentHeight to editableRowAreaHeight div rowCount
	
	tell document 1
		tell current page
			set startPointHorizontal to sideLeftMarginWidth
			set endPointHorizontal to documentWidth - sideRightMarginWidth
			
			set thisStartPointVertical to verticalTopMarginHeight
			set thisEndPointVertical to verticalTopMarginHeight
			
			set repeatCount to rowCount + 1 -- add a line for the bottom
			repeat with i from 1 to the repeatCount
				-- MAKE LINE
				set newLine to make new line
				tell newLine
					set start point to {startPointHorizontal, thisStartPointVertical}
					set end point to {endPointHorizontal, thisEndPointVertical}
					set locked to true
				end tell
				
				if i is not 1 and i is not repeatCount then
					-- ADD GUTTER
					set thisStartPointVertical to thisStartPointVertical + gutterHeight
					set thisEndPointVertical to thisEndPointVertical + gutterHeight
					set newLine to make new line
					tell newLine
						set start point to {startPointHorizontal, thisStartPointVertical}
						set end point to {endPointHorizontal, thisEndPointVertical}
						set locked to true
					end tell
					-- INCREMENT VERTICAL POSITION
					set thisStartPointVertical to thisStartPointVertical + editableSegmentHeight
					set thisEndPointVertical to thisEndPointVertical + editableSegmentHeight
				else
					-- INCREMENT VERTICAL POSITION
					set thisStartPointVertical to thisStartPointVertical + editableSegmentHeight
					set thisEndPointVertical to thisEndPointVertical + editableSegmentHeight
				end if
			end repeat
		end tell
	end tell
end tell

on promptForIntegerValue(thisPrompt, minimumValue, maximumValue, defaultValue)
	tell application "Pages"
		repeat
			display dialog thisPrompt default answer (defaultValue as string)
			try
				set thisValue to (the text returned of the result) as integer
				if thisValue is greater than or equal to minimumValue and thisValue is less than or equal to maximumValue then
					return thisValue
				end if
			on error
				beep
			end try
		end repeat
	end tell
end promptForIntegerValue
