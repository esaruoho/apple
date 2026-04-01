property selectedRangeBackgroundColor : {65535, 65535, 65535}
property selectedRangeTextColor : {0, 0, 0}
property backgroundDataColor : {39321, 39321, 39321}
property headerHightlightTextColor : {65535, 65535, 65535}
property lightnessValue : 15000

tell application "Keynote"
	activate
	try
		if not (exists document 1) then error number 1000
		tell document 1
			set sourceSlide to the current slide
			tell sourceSlide
				set thisSlideNumber to its slide number
				try
					set the selectedTable to ¬
						(the first table whose class of selection range is range)
				on error
					error number 1001
				end try
				tell selectedTable
					set the selectionRangeName to the name of selection range
					set the headerColumnCount to header column count
					set the headerRowCount to header row count
					set the footerRowCount to footer row count
					set the tableDataRangeStart to ¬
						the name of cell (headerColumnCount + 1) of row (headerRowCount + 1)
					set the tableDataRangeEnd to ¬
						the name of cell -1 of row ((footerRowCount + 1) * -1)
					set tableDataRange to range (tableDataRangeStart & ":" & tableDataRangeEnd)
				end tell
			end tell
			duplicate sourceSlide to after sourceSlide
			set duplicateSlide to slide (thisSlideNumber + 1)
			tell duplicateSlide
				set the transition properties to {automatic transition:false}
				tell table 1
					set the tableDataRangeStart to ¬
						the name of cell (headerColumnCount + 1) of row (headerRowCount + 1)
					set the tableDataRangeEnd to ¬
						the name of cell -1 of row ((footerRowCount + 1) * -1)
					set tableDataRange to range (tableDataRangeStart & ":" & tableDataRangeEnd)
					set text color of tableDataRange to backgroundDataColor
					
					if headerColumnCount is not 0 then
						copy background color of last cell of column 1 to {RValue, GValue, BValue}
						set lighterColumnColor to my lightenRGB(RValue, GValue, BValue, lightnessValue)
						tell columns 1 thru headerColumnCount
							set text color to backgroundDataColor
						end tell
					end if
					
					if headerRowCount is not 0 then
						copy background color of last cell of row 1 to {RValue, GValue, BValue}
						set lighterRowColor to my lightenRGB(RValue, GValue, BValue, lightnessValue)
						tell rows 1 thru headerRowCount
							set text color to backgroundDataColor
						end tell
					end if
					
					tell range selectionRangeName
						if headerColumnCount is not 0 then
							set the text color of cells 1 thru ¬
								headerColumnCount of its row to headerHightlightTextColor
							set the background color of cells 1 thru ¬
								headerColumnCount of its row to lighterColumnColor
						end if
						if headerRowCount is not 0 then
							set the text color of cells 1 thru ¬
								headerRowCount of its column to headerHightlightTextColor
							set the background color of cells 1 thru ¬
								headerRowCount of its column to lighterRowColor
						end if
						set background color to selectedRangeBackgroundColor
						set text color to selectedRangeTextColor
					end tell
				end tell
			end tell
			tell sourceSlide
				set the transition properties to ¬
					{transition effect:dissolve ¬
						, transition delay:0 ¬
						, transition duration:0.75 ¬
						, automatic transition:false}
			end tell
		end tell
		start document 1 from sourceSlide
	on error errorMessage number errorNumber
		if errorNumber is 1000 then
			set alertString to "MISSING RESOURCE"
			set errorMessage to "Please create or open a document before running this script."
		else if errorNumber is 1001 then
			set alertString to "SELECTION ERROR"
			set errorMessage to "Please select a table before running this script."
		else
			set alertString to "EXECUTION ERROR"
		end if
		if errorNumber is not -128 then
			display alert alertString message errorMessage buttons {"Cancel"}
		end if
		error number -128
	end try
end tell

on lightenRGB(RValue, GValue, BValue, lightenAmount)
	if RValue + lightenAmount is greater than 65535 then
		set RValue to 65535
	else
		set RValue to RValue + lightenAmount
	end if
	if GValue + lightenAmount is greater than 65535 then
		set GValue to 65535
	else
		set GValue to GValue + lightenAmount
	end if
	if BValue + lightenAmount is greater than 65535 then
		set BValue to 65535
	else
		set BValue to BValue + lightenAmount
	end if
	return {RValue, GValue, BValue}
end lightenRGB
