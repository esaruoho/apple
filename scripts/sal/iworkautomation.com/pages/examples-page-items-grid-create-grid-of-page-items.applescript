use AppleScript version "2.3.1"
use scripting additions
use framework "Foundation"
use framework "AppKit"
use framework "CoreImage"

property defaultTopMarginHeight : 36
property defaultBottomMarginHeight : 36
property defaultLeftMarginWidth : 36
property defaultRightMarginWidth : 36
property defaultColumnGutterWidth : 12
property defaultRowGutterHeight : 12
property defaultColumnCount : 3
property defaultRowCount : 6

property paperSizeNames : {"US Letter", "US Legal", "A3", "A4", "A5", "JIS B5", "B5", "Envelope #10", "Envelope DL", "Tabloid", "Tabloid Oversize", "ROC 16K", "Envelope Choukei 3", "Super B/A3"}
property paperSizeDimensions : {{612, 792}, {612, 1008}, {842, 1191}, {595, 842}, {420, 595}, {516, 729}, {499, 709}, {297, 684}, {312, 624}, {792, 1224}, {864, 1296}, {558, 774}, {340, 666}, {936, 1368}}

tell application id "com.apple.iWork.Pages"
	activate
	
	if not (exists document 1) then error number -128
	
	set paperSizePrompt to "What is this document’s paper size?"
	set chosenPageSize to (choose from list paperSizeNames with prompt paperSizePrompt default items (item 1 of paperSizeNames))
	if chosenPageSize is false then error number -128
	set chosenPageSize to chosenPageSize as string
	set thisPageDimensions to item (my indexOfItemInList(chosenPageSize, paperSizeNames)) of paperSizeDimensions
	
	set orientationPrompt to "Is the page orientation set to landscape or portrait?"
	display dialog orientationPrompt buttons {"Cancel", "Landscape", "Portrait"} default button 3
	if the button returned of the result is "Landscape" then
		set thisPageDimensions to the reverse of thisPageDimensions
	end if
	
	copy thisPageDimensions to {documentWidth, documentHeight}
	
	set objectTypePrompt to "Do you want to create just images, just text items, or both image and text items as pairs?"
	display dialog objectTypePrompt buttons {"Images", "Text Items", "Both"} default button 3
	set the objectType to the button returned of the result
	
	set topMarginPrompt to "Enter the size of the TOP page margin to use (in pixels):"
	set topMarginHeight to my promptForIntegerValue(topMarginPrompt, 0, documentHeight div 2, defaultTopMarginHeight)
	
	set bottomMarginPrompt to "Enter the size of the BOTTOM page margin to use (in pixels):"
	set bottomMarginHeight to my promptForIntegerValue(bottomMarginPrompt, 0, documentHeight div 2, defaultBottomMarginHeight)
	
	set leftMarginPrompt to "Enter the size of the LEFT page margin to use (in pixels):"
	set leftMarginWidth to my promptForIntegerValue(leftMarginPrompt, 0, documentHeight div 2, defaultLeftMarginWidth)
	
	set rightMarginPrompt to "Enter the size of RIGHT page margin to use (in pixels):"
	set rightMarginWidth to my promptForIntegerValue(rightMarginPrompt, 0, documentHeight div 2, defaultRightMarginWidth)
	
	set columnGutterPrompt to "Enter the space between columns (in pixels):"
	set columnGutterWidth to my promptForIntegerValue(columnGutterPrompt, 0, 100, defaultColumnGutterWidth)
	
	set rowGutterPrompt to "Enter the space between rows (in pixels):"
	set rowGutterHeight to my promptForIntegerValue(rowGutterPrompt, 0, 100, defaultRowGutterHeight)
	
	set columnCountPrompt to "Enter the column count:"
	set columnCount to my promptForIntegerValue(columnCountPrompt, 2, 20, defaultColumnCount)
	
	if objectType is "Both" then
		set rowCountForBothPrompt to "Since you’ve chosen to create paired image and text rows, enter the total row count (including both image and text rows):" & return & return & "(This value must be an even number)"
		repeat
			set rowCount to my promptForIntegerValue(rowCountForBothPrompt, 2, 20, defaultRowCount)
			if rowCount mod 2 is 0 then
				exit repeat
			else
				beep
			end if
		end repeat
	else
		set rowCountPrompt to "Enter the row count:"
		set rowCount to my promptForIntegerValue(rowCountPrompt, 2, 20, defaultRowCount)
	end if
	
	set pageIdentiferPrompt to "Do you want add identifiers to the page items?"
	display dialog pageIdentiferPrompt buttons {"Cancel", "No", "Yes"} default button 3
	if (the button returned of the result) is "Yes" then
		set shouldAddID to true
	else
		set shouldAddID to false
	end if
	
	set columnGutterCount to columnCount - 1
	set rowGutterCount to rowCount - 1
	
	set editableAreaWidth to documentWidth - leftMarginWidth - rightMarginWidth
	set editableAreaHeight to documentHeight - topMarginHeight - bottomMarginHeight
	
	set editableColumnAreaWidth to editableAreaWidth - (columnGutterCount * columnGutterWidth)
	set editableRowAreaHeight to editableAreaHeight - (rowGutterCount * rowGutterHeight)
	
	set shapeWidth to editableColumnAreaWidth div columnCount
	set shapeHeight to editableRowAreaHeight div rowCount
	
	set targetImageFilePath to the POSIX path of (path to pictures folder) & "placeholder.jpg"
	my createCustomPlaceholderImageFile(shapeWidth, shapeHeight, targetImageFilePath, false)
	set targetImageFile to targetImageFilePath as POSIX file
	
	tell document 1
		tell current page
			set thisHorizontalOffset to leftMarginWidth
			set thisVerticalOffset to topMarginHeight
			set itemCounter to 0
			set textItemCount to 0
			set imageItemCount to 0
			repeat with i from 1 to rowCount
				repeat with q from 1 to columnCount
					if the objectType is "Images" then
						set itemCounter to itemCounter + 1
						set placeholderText to "PLACEHOLDER-" & (itemCounter as text)
						set thisImage to make new image with properties {file:targetImageFile, width:shapeWidth, height:shapeHeight, position:{thisHorizontalOffset, thisVerticalOffset}, description:placeholderText}
						delay 0.5
						tell application "System Events" to keystroke "i" using {control down, command down, option down}
						delay 0.5
					else if the objectType is "Text Items" then
						if shouldAddID is true then
							set itemCounter to itemCounter + 1
							set placeholderText to "PLACEHOLDER-" & (itemCounter as text)
						else
							set placeholderText to ""
						end if
						make new text item with properties {width:shapeWidth, height:shapeHeight, position:{thisHorizontalOffset, thisVerticalOffset}, object text:placeholderText}
					else if the objectType is "Both" then
						if i mod 2 is 0 then -- even row is text items
							if shouldAddID is true then
								set textItemCount to textItemCount + 1
								set placeholderText to "TEXT-" & textItemCount as text
							else
								set placeholderText to ""
							end if
							make new text item with properties {width:shapeWidth, height:shapeHeight, position:{thisHorizontalOffset, thisVerticalOffset}, object text:placeholderText}
						else -- odd row is images
							if shouldAddID is true then
								set imageItemCount to imageItemCount + 1
								set placeholderText to "IMAGE-" & imageItemCount as text
							else
								set placeholderText to ""
							end if
							set thisImage to make new image with properties {file:targetImageFile, width:shapeWidth, height:shapeHeight, position:{thisHorizontalOffset, thisVerticalOffset}, description:placeholderText}
							if shouldAddID is true then set description of thisImage to placeholderText
							delay 0.5
							tell application "System Events" to keystroke "i" using {control down, command down, option down}
							delay 0.5
						end if
					end if
					set thisHorizontalOffset to thisHorizontalOffset + columnGutterWidth + shapeWidth
				end repeat
				set thisHorizontalOffset to leftMarginWidth
				set thisVerticalOffset to thisVerticalOffset + rowGutterHeight + shapeHeight
			end repeat
		end tell
	end tell
end tell
tell application id "com.apple.Finder" to move targetImageFile to the trash

on promptForIntegerValue(thisPrompt, minimumValue, maximumValue, defaultValue)
	tell application id "com.apple.iWork.Pages"
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

on indexOfItemInList(aValue, theList)
	set theArray to current application's NSArray's arrayWithArray:theList
	set theIndex to theArray's indexOfObject:aValue
	return (theIndex + 1)
end indexOfItemInList

on createCustomPlaceholderImageFile(aWidth, aHeight, targetImageFilePath, shouldReveal)
	set aColor to current application's NSColor's grayColor
	set aSize to {width:aWidth, height:aHeight}
	set aRect to current application's NSMakeRect(0, 0, aWidth, aHeight)
	set aImage to current application's NSImage's alloc()'s initWithSize:aSize
	aImage's lockFocus()
	aColor's drawSwatchInRect:aRect
	aImage's unlockFocus()
	set aResult to writeNSImageObjectToFileAsJPEG(aImage, targetImageFilePath, shouldReveal)
	return aResult
end createCustomPlaceholderImageFile

on writeNSImageObjectToFileAsJPEG(thisImageObject, targetImageFilePath, shouldRevealInFinder)
	-- create JPEG data for the image object
	set tiffData to thisImageObject's TIFFRepresentation()
	set imageRep to current application's NSBitmapImageRep's imageRepWithData:tiffData
	set theProps to current application's NSDictionary's dictionaryWithObject:1.0 forKey:(current application's NSImageCompressionFactor)
	set imageData to (imageRep's representationUsingType:(current application's NSJPEGFileType) |properties|:theProps)
	
	-- write the JPEG data to file
	set theResult to (imageData's writeToFile:targetImageFilePath atomically:true |error|:(missing value)) as boolean
	if theResult is true then
		if shouldRevealInFinder is true then
			set theseURLs to {}
			set the end of theseURLs to (current application's NSURL's fileURLWithPath:targetImageFilePath)
			-- reveal items in file viewer
			tell current application's NSWorkspace to set theWorkspace to sharedWorkspace()
			tell theWorkspace to activateFileViewerSelectingURLs:theseURLs
		end if
		return true
	else
		error "There was a problem writing the image object to file."
	end if
end writeNSImageObjectToFileAsJPEG
