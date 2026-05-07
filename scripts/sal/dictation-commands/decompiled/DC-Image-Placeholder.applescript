use framework "Foundation"
use framework "AppKit"
use framework "CoreImage"
use scripting additions

property nameDelimiter : "-"

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


(* CHOOSING PLACEHOLDER *)

on chooseImageForGrid(targetAppID)
	set placeholderOptions to {"1x1 Square", "2x3 APS Classic Portrait", "3x2 APS Classic Landscape", "3x4 Portrait", "4x3 Landscape", "16x9 APS HD", "3x1 APS Panoramic", "4x1 Extended Panorama"}
	tell application id targetAppID
		activate
		set shapePrompt to my getLocalizedStringForKey("SHAPE_CHOICE_PROMPT")
		say shapePrompt without waiting until completion
		set chosenItem to (choose from list placeholderOptions default items (item 1 of placeholderOptions))
		say " " with stopping current speech
		if chosenItem is false then
			error number -128
		else
			set chosenItem to chosenItem as text
			set placeholderIndicator to (my indexOfItemInList(chosenItem, placeholderOptions)) - 1
		end if
	end tell
end chooseImageForGrid

on choosePlaceholderImage(targetAppID)
	set placeholderOptions to {"1x1 Square", "2x3 APS Classic Portrait", "3x2 APS Classic Landscape", "3x4 Portrait", "4x3 Landscape", "16x9 APS HD", "3x1 APS Panoramic", "4x1 Extended Panorama"}
	tell application id targetAppID
		activate
		set shapePrompt to my getLocalizedStringForKey("SHAPE_CHOICE_PROMPT")
		say shapePrompt without waiting until completion
		set chosenItem to (choose from list placeholderOptions default items (item 1 of placeholderOptions))
		say " " with stopping current speech
		if chosenItem is false then
			error number -128
		else
			set chosenItem to chosenItem as text
			set placeholderIndicator to (my indexOfItemInList(chosenItem, placeholderOptions)) - 1
			if targetAppID is "com.apple.iWork.Keynote" then
				if placeholderIndicator is in {5, 6, 7} then
					set defaultButtonIndex to 3
				else
					set defaultButtonIndex to 2
				end if
			else
				set defaultButtonIndex to 1
			end if
			set sizePrompt to my getLocalizedStringForKey("SIZE_CHOICE_PROMPT")
			set smallButtonTitle to my getLocalizedStringForKey("SMALL_BUTTON_TITLE")
			set mediumButtonTitle to my getLocalizedStringForKey("MEDIUM_BUTTON_TITLE")
			set largeButtonTitle to my getLocalizedStringForKey("LARGE_BUTTON_TITLE")
			set localizedOr to my getLocalizedStringForKey("LOCALIZED_OR")
			say (smallButtonTitle & ", " & mediumButtonTitle & ", " & localizedOr & space & largeButtonTitle & "?") with stopping current speech without waiting until completion
			display dialog sizePrompt & ":" buttons {smallButtonTitle, mediumButtonTitle, largeButtonTitle} default button defaultButtonIndex
			set sizeTitle to the button returned of the result
			if sizeTitle is smallButtonTitle then
				set sizeIndicator to 0
			else if sizeTitle is mediumButtonTitle then
				set sizeIndicator to 1
			else
				set sizeIndicator to 2
			end if
			return {placeholderIndicator, sizeIndicator}
		end if
	end tell
end choosePlaceholderImage

on generateDescriptonsForPlaceholders()
	set descriptionLead to my getLocalizedStringForKey("PLACEHOLDER_DESCRIPTION_LEAD") --  "An image placeholder with an aspect ratio of"
	set horizontalTerm to my getLocalizedStringForKey("ASPECT_TERM_HORIZONTAL") -- "horizontal"
	set verticalTerm to my getLocalizedStringForKey("ASPECT_TERM_VERTICAL") -- "vertical"
	set comparisonOperatorTerm to my getLocalizedStringForKey("ASPECT_COMPARISON_OPERATOR_TERM") -- "to" 
	set placeholderDescriptions to {descriptionLead & space & "1" & space & horizontalTerm & space & comparisonOperatorTerm & space & "1" & space & verticalTerm, ¬
		descriptionLead & space & "2" & space & horizontalTerm & space & comparisonOperatorTerm & space & "3" & space & verticalTerm, ¬
		descriptionLead & space & "3" & space & horizontalTerm & space & comparisonOperatorTerm & space & "2" & space & verticalTerm, ¬
		descriptionLead & space & "3" & space & horizontalTerm & space & comparisonOperatorTerm & space & "4" & space & verticalTerm, ¬
		descriptionLead & space & "4" & space & horizontalTerm & space & comparisonOperatorTerm & space & "3" & space & verticalTerm, ¬
		descriptionLead & space & "16" & space & horizontalTerm & space & comparisonOperatorTerm & space & "9" & space & verticalTerm, ¬
		descriptionLead & space & "3" & space & horizontalTerm & space & comparisonOperatorTerm & space & "1" & space & verticalTerm, ¬
		descriptionLead & space & "4" & space & horizontalTerm & space & comparisonOperatorTerm & space & "1" & space & verticalTerm}
	return placeholderDescriptions
end generateDescriptonsForPlaceholders

(* KEYNOTE *)
on addChosenPlaceholderToKeynote()
	copy choosePlaceholderImage("com.apple.iWork.Keynote") to {placeholderIndicator, sizeIndicator}
	addPlaceholderToKeynote(placeholderIndicator, sizeIndicator)
	-- store the JXA call to this handler
	set JXACommandString to "Library('DC-Image-Placeholder').addChosenPlaceholderToKeynote();"
	tell script "DC-Support" to storeJXACommandString(JXACommandString)
end addChosenPlaceholderToKeynote

on addPlaceholderToKeynote(placeholderIndicator, sizeIndicator)
	(* placeholderIndicator: 0 = 1x1, 1 = 2x3, 2 = 3x2, 3 = 3x4, 4 = 4x3, 5 = 16x9, 6 = 3x1, 7 = 4x1 *)
	(* sizeIndicator: 0 = small (1/4 slide height), 1 = medium (1/2 slide height), 2 = full *)
	set placeholderDescriptions to generateDescriptonsForPlaceholders()
	set aDescription to (item (placeholderIndicator + 1) of placeholderDescriptions)
	try
		tell application id "com.apple.iWork.Keynote"
			activate
			if not (exists document 1) then
				error "KEYNOTE_NO_DOCUMENT"
			end if
			--set imageFile to my createPlaceholderImage(placeholderIndicator)
			set imageFile to my generatePlaceholderImageFileForPlacement(placeholderIndicator, sizeIndicator)
			tell front document
				set documentWidth to its «class sitw»
				set documentHeight to its «class sith»
				if sizeIndicator is 0 then
					set imageTargetHeight to documentHeight div 4
				else if sizeIndicator is 1 then
					set imageTargetHeight to documentHeight div 2
				else if sizeIndicator is 2 then
					set imageTargetHeight to documentHeight
				end if
				tell «class crsl»
					set newImage to make new «class imag» with properties {file:imageFile}
					set «class dscr» of newImage to aDescription
					set «class sith» of newImage to imageTargetHeight
					if «class sitw» of newImage is greater than documentWidth then
						set «class sitw» of newImage to documentWidth
					end if
					set «class sipo» of newImage to {(documentWidth - («class sitw» of newImage)) div 2, (documentHeight - («class sith» of newImage)) div 2}
					set «class pLck» of newImage to false
					tell application "System Events" to keystroke "i" using {control down, command down, option down}
				end tell
			end tell
		end tell
		tell current application to delay 0.5
		tell script "DC-Workspace" to deleteItem(imageFile)
		announceCompletion()
	on error errorMessage number errorNumber
		my displaySpokenErrorAlert(errorMessage, "com.apple.iWork.Keynote")
	end try
end addPlaceholderToKeynote

(* PAGES *)
on addChosenPlaceholderToPages()
	copy choosePlaceholderImage("com.apple.iWork.Pages") to {placeholderIndicator, sizeIndicator}
	addPlaceholderToPages(placeholderIndicator, sizeIndicator)
	-- store the JXA call to this handler
	set JXACommandString to "Library('DC-Image-Placeholder').addChosenPlaceholderToPages();"
	tell script "DC-Support" to storeJXACommandString(JXACommandString)
	announceCompletion()
end addChosenPlaceholderToPages

on addCustomImagePlaceholderToPages(imageTargetWidth, imageTargetHeight)
	try
		tell application id "com.apple.iWork.Pages"
			activate
			if not (exists document 1) then
				error "PAGES_NO_DOCUMENT"
			end if
			set imageFile to my generateCustomPlaceholderImageFileForPlacement(imageTargetWidth, imageTargetHeight)
			tell front document
				tell current page
					set newImage to make new image with properties {file:imageFile, width:imageTargetWidth, height:imageTargetHeight}
					set locked of newImage to false
					tell application "System Events" to keystroke "i" using {control down, command down, option down}
				end tell
			end tell
		end tell
		tell current application to delay 0.5
		tell script "DC-Workspace" to deleteItem(imageFile)
		tell application id "com.apple.iWork.Pages"
			return newImage
		end tell
	on error errorMessage number errorNumber
		my displaySpokenErrorAlert(errorMessage, "com.apple.iWork.Pages")
	end try
end addCustomImagePlaceholderToPages

on addCustomImagePlaceholderToPagesMatchingSizeOfSelectedItem()
	try
		tell application "Pages" to activate
		tell application "System Events"
			tell process "Pages"
				set y to entire contents of window 1
				set selectedItems to {}
				repeat with i from 1 to the count of y
					set thisItem to item i of y
					if selected of thisItem is true and role of thisItem is "AXLayoutItem" then
						set the end of selectedItems to thisItem
					end if
				end repeat
				if (count of selectedItems) is not 1 then error "SELECT_SINGLE_ITEM"
				set thisItem to item 1 of selectedItems
				log (get properties of thisItem)
				copy size of thisItem to {itemWidth, itemHeight}
			end tell
		end tell
		tell script "DC-Image-Placeholder"
			addCustomImagePlaceholderToPages(itemWidth, itemHeight)
		end tell
	on error errorMessage number errorNumber
		my displaySpokenErrorAlert(errorMessage, "com.apple.iWork.Pages")
	end try
end addCustomImagePlaceholderToPagesMatchingSizeOfSelectedItem

on addPlaceholderToPages(placeholderIndicator, sizeIndicator)
	(* placeholderIndicator: 0 = 1x1, 1 = 2x3, 2 = 3x2, 3 = 3x4, 4 = 4x3, 5 = 16x9, 6 = 3x1, 7 = 4x1 *)
	(* sizeIndicator: 0 = small, 1 = medium, 2 = large *)
	set placeholderDescriptions to generateDescriptonsForPlaceholders()
	set aDescription to (item (placeholderIndicator + 1) of placeholderDescriptions)
	try
		tell application id "com.apple.iWork.Pages"
			activate
			if not (exists document 1) then
				error "PAGES_NO_DOCUMENT"
			end if
			set imageFile to my generatePlaceholderImageFileForPlacement(placeholderIndicator, sizeIndicator)
			copy my deriveImageDimensions(sizeIndicator, placeholderIndicator) to {imageTargetWidth, imageTargetHeight}
			tell front document
				tell current page
					set newImage to make new image with properties {file:imageFile, width:imageTargetWidth, height:imageTargetHeight, description:aDescription}
					set locked of newImage to false
					tell application "System Events" to keystroke "i" using {control down, command down, option down}
				end tell
			end tell
		end tell
		tell current application to delay 0.5
		tell script "DC-Workspace" to deleteItem(imageFile)
		tell application id "com.apple.iWork.Pages"
			return newImage
		end tell
	on error errorMessage number errorNumber
		my displaySpokenErrorAlert(errorMessage, "com.apple.iWork.Pages")
	end try
end addPlaceholderToPages

on addPlaceholderTextToTextItem(aTextBox, placeholderText)
	tell application id "com.apple.iWork.Pages"
		set locked of aTextBox to false
		delay 0.5
		tell application "System Events" to key code 76
		delay 0.5
		tell application "System Events" to keystroke placeholderText
		delay 0.5
		tell application "System Events" to keystroke "a" using command down
		delay 0.5
		tell application "System Events" to keystroke "t" using {control down, command down, option down}
		delay 0.5
	end tell
end addPlaceholderTextToTextItem

on promptForIntegerValue(thisPrompt, thisSpokenPrompt, minimumValue, maximumValue, defaultValue)
	tell application id "com.apple.iWork.Pages"
		say thisSpokenPrompt without waiting until completion
		repeat
			display dialog thisPrompt default answer (defaultValue as string)
			try
				set thisValue to (the text returned of the result) as integer
				say " " with stopping current speech
				if thisValue is greater than or equal to minimumValue and thisValue is less than or equal to maximumValue then
					return thisValue
				end if
			on error
				say " " with stopping current speech
				beep
			end try
		end repeat
	end tell
end promptForIntegerValue

on determinePlaceholderHeightGivenWidth(placeholderIndicator, placeholderWidth)
	(* placeholderIndicator: 0 = 1x1, 1 = 2x3, 2 = 3x2, 3 = 3x4, 4 = 4x3, 5 = 16x9, 6 = 3x1, 7 = 4x1 *)
	if placeholderIndicator is 0 then
		return placeholderWidth
	else if placeholderIndicator is 1 then
		set xFactor to 2
		set yFactor to 3
	else if placeholderIndicator is 2 then
		set xFactor to 3
		set yFactor to 2
	else if placeholderIndicator is 3 then
		set xFactor to 3
		set yFactor to 4
	else if placeholderIndicator is 4 then
		set xFactor to 4
		set yFactor to 3
	else if placeholderIndicator is 5 then
		set xFactor to 16
		set yFactor to 9
	else if placeholderIndicator is 6 then
		set xFactor to 3
		set yFactor to 1
	else if placeholderIndicator is 7 then
		set xFactor to 4
		set yFactor to 1
	end if
	return ((yFactor * placeholderWidth) / xFactor) as integer
end determinePlaceholderHeightGivenWidth

(* NUMBERS *)
on addChosenPlaceholderToNumbers()
	copy choosePlaceholderImage("com.apple.iWork.Numbers") to {placeholderIndicator, sizeIndicator}
	addPlaceholderToNumbers(placeholderIndicator, sizeIndicator)
	-- store the JXA call to this handler
	set JXACommandString to "Library('DC-Image-Placeholder').addChosenPlaceholderToNumbers();"
	tell script "DC-Support" to storeJXACommandString(JXACommandString)
end addChosenPlaceholderToNumbers

on addPlaceholderToNumbers(placeholderIndicator, sizeIndicator)
	(* placeholderIndicator: 0 = 1x1, 1 = 2x3, 2 = 3x2, 3 = 3x4, 4 = 4x3, 5 = 16x9, 6 = 3x1, 7 = 4x1 *)
	(* sizeIndicator: 0 = small, 1 = medium, 2 = large *)
	set placeholderDescriptions to generateDescriptonsForPlaceholders()
	set aDescription to (item (placeholderIndicator + 1) of placeholderDescriptions)
	try
		tell application id "com.apple.iWork.Numbers"
			activate
			if not (exists document 1) then
				error "NUMBERS_NO_DOCUMENT"
			end if
			set imageFile to my generatePlaceholderImageFileForPlacement(placeholderIndicator, sizeIndicator)
			copy my deriveImageDimensions(sizeIndicator, placeholderIndicator) to {imageTargetWidth, imageTargetHeight}
			tell front document
				tell active sheet
					set newImage to make new image with properties {file:imageFile, width:imageTargetWidth, height:imageTargetHeight, description:aDescription}
					set locked of newImage to false
					tell application "System Events" to keystroke "i" using {control down, command down, option down}
				end tell
			end tell
		end tell
		tell current application to delay 0.5
		tell script "DC-Workspace" to deleteItem(imageFile)
		announceCompletion()
	on error errorMessage number errorNumber
		my displaySpokenErrorAlert(errorMessage, "com.apple.iWork.Numbers")
	end try
end addPlaceholderToNumbers

on deriveImageDimensions(sizeIndicator, placeholderIndicator)
	(* placeholderIndicator: 0 = 1x1, 1 = 2x3, 2 = 3x2, 3 = 3x4, 4 = 4x3, 5 = 16x9, 6 = 3x1, 7 = 4x1 *)
	(* sizeIndicator: 0 = small, 1 = medium, 2 = full *)
	if sizeIndicator is 0 then -- small
		if placeholderIndicator is 0 then -- 1x1
			set imageTargetWidth to 128
			set imageTargetHeight to 128
		else if placeholderIndicator is 1 then -- 2x3
			set imageTargetWidth to 128
			set imageTargetHeight to 192
		else if placeholderIndicator is 2 then -- 3x2
			set imageTargetWidth to 192
			set imageTargetHeight to 128
		else if placeholderIndicator is 3 then -- 3x4
			set imageTargetWidth to 128
			set imageTargetHeight to 171
		else if placeholderIndicator is 4 then -- 4x3
			set imageTargetWidth to 171
			set imageTargetHeight to 128
		else if placeholderIndicator is 5 then -- 16x9
			set imageTargetWidth to 256
			set imageTargetHeight to 144
		else if placeholderIndicator is 6 then -- 3x1
			set imageTargetWidth to 384
			set imageTargetHeight to 128
		else if placeholderIndicator is 7 then -- 4x1
			set imageTargetWidth to 448
			set imageTargetHeight to 112
		end if
	else if sizeIndicator is 1 then -- medium
		if placeholderIndicator is 0 then -- 1x1
			set imageTargetWidth to 256
			set imageTargetHeight to 256
		else if placeholderIndicator is 1 then -- 2x3
			set imageTargetWidth to 256
			set imageTargetHeight to 384
		else if placeholderIndicator is 2 then -- 3x2
			set imageTargetWidth to 384
			set imageTargetHeight to 256
		else if placeholderIndicator is 3 then -- 3x4
			set imageTargetWidth to 256
			set imageTargetHeight to 341
		else if placeholderIndicator is 4 then -- 4x3
			set imageTargetWidth to 341
			set imageTargetHeight to 256
		else if placeholderIndicator is 5 then -- 16x9
			set imageTargetWidth to 384
			set imageTargetHeight to 216
		else if placeholderIndicator is 6 then -- 3x1
			set imageTargetWidth to 576
			set imageTargetHeight to 192
		else if placeholderIndicator is 7 then -- 4x1
			set imageTargetWidth to 640
			set imageTargetHeight to 160
		end if
	else if sizeIndicator is 2 then -- large
		if placeholderIndicator is 0 then -- 1x1
			set imageTargetWidth to 512
			set imageTargetHeight to 512
		else if placeholderIndicator is 1 then -- 2x3
			set imageTargetWidth to 341
			set imageTargetHeight to 512
		else if placeholderIndicator is 2 then -- 3x2
			set imageTargetWidth to 512
			set imageTargetHeight to 341
		else if placeholderIndicator is 3 then -- 3x4
			set imageTargetWidth to 384
			set imageTargetHeight to 512
		else if placeholderIndicator is 4 then -- 4x3
			set imageTargetWidth to 512
			set imageTargetHeight to 384
		else if placeholderIndicator is 5 then -- 16x9
			set imageTargetWidth to 512
			set imageTargetHeight to 288
		else if placeholderIndicator is 6 then -- 3x1
			set imageTargetWidth to 768
			set imageTargetHeight to 256
		else if placeholderIndicator is 7 then -- 4x1
			set imageTargetWidth to 774
			set imageTargetHeight to 194
		end if
	end if
	log {imageTargetWidth, imageTargetHeight}
	return {imageTargetWidth, imageTargetHeight}
end deriveImageDimensions

(* IMAGE FILE CREATION HANDLERS *)

on generatePlaceholderImageFileForPlacement(placeholderIndicator, sizeIndicator)
	copy deriveImageDimensions(sizeIndicator, placeholderIndicator) to {imageTargetWidth, imageTargetHeight}
	set targetImageFilePath to the POSIX path of (path to "cach" from user domain) & ("placeholder" & "-" & imageTargetWidth & "x" & imageTargetHeight & ".jpg") as text
	createCustomPlaceholderImageFile(imageTargetWidth, imageTargetHeight, targetImageFilePath, false)
	return (targetImageFilePath as POSIX file)
end generatePlaceholderImageFileForPlacement

on generateCustomPlaceholderImageFileForPlacement(imageTargetWidth, imageTargetHeight)
	set targetImageFilePath to the POSIX path of (path to "cach" from user domain) & ("placeholder" & "-" & imageTargetWidth & "x" & imageTargetHeight & ".jpg") as text
	createCustomPlaceholderImageFile(imageTargetWidth, imageTargetHeight, targetImageFilePath, false)
	return (targetImageFilePath as POSIX file)
end generateCustomPlaceholderImageFileForPlacement

on createCustomPlaceholderImageFile(aWidth, aHeight, targetImageFilePath, shouldReveal)
	set aColor to current application's NSColor's grayColor
	set aSize to {width:aWidth, height:aHeight}
	set aRect to current application's NSMakeRect(0, 0, aWidth, aHeight)
	set aImage to current application's NSImage's alloc()'s initWithSize:aSize
	aImage's lockFocus()
	aColor's drawSwatchInRect:aRect
	aImage's unlockFocus()
	writeNSImageObjectToFileAsJPEG(aImage, targetImageFilePath, shouldReveal)
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

(* SUPPORT HANDLERS *)

on indexOfItemInList(aValue, theList)
	set theArray to current application's NSArray's arrayWithArray:theList
	set theIndex to theArray's indexOfObject:aValue
	return (theIndex + 1)
end indexOfItemInList

on stringFromList(thisList, thisDelimiterString)
	set thisArray to current application's NSArray's arrayWithArray:thisList
	set combinedItemsString to (thisArray's componentsJoinedByString:thisDelimiterString) as text
	return combinedItemsString as text
end stringFromList

on writeImageDataToFile(thisData, HFSFilePath, shouldAppendData)
	try
		tell current application
			set the HFSFilePath to the HFSFilePath as string
			set the aNewFile to open for access file HFSFilePath with write permission
			if shouldAppendData is false then set eof of the aNewFile to 0
			write thisData to the aNewFile starting at eof --as «class PNGf»
			close access the aNewFile
			return true
		end tell
	on error errorMessage
		log errorMessage
		try
			tell current application
				close access file HFSFilePath
			end tell
		end try
		return false
	end try
end writeImageDataToFile

on displaySpokenErrorAlert(errorKey, appID)
	if appID is "" or appID is missing value then
		set aWorkspace to current application's NSWorkspace's sharedWorkspace
		set frontmostApp to aWorkspace's frontmostApplication
		set appID to (frontmostApp's bundleIdentifier) as text
	end if
	try
		set errorTitle to getLocalizedStringForKey("ERROR_TITLE")
		set errorMessage to getLocalizedStringForKey(errorKey)
		set cancelButtonTitle to getLocalizedStringForKey("CANCEL_BUTTON_TITLE")
		tell current application
			say errorMessage without waiting until completion
		end tell
		tell application id appID
			activate
			display alert errorTitle message errorMessage buttons {cancelButtonTitle}
		end tell
		-- stop speaking
		say " " with stopping current speech
		return true
	on error errorMessage
		log errorMessage
		error number -128
	end try
end displaySpokenErrorAlert

on getLocalizedStringForKey(thisKey)
	set thisBundlePath to (path to me)
	set aLocalizedString to (localized string thisKey in bundle thisBundlePath)
	log aLocalizedString
	return aLocalizedString
end getLocalizedStringForKey

on announceCompletion()
	say (my getLocalizedStringForKey("SUCCESSFUL_COMPLETION_PHRASE")) with stopping current speech
end announceCompletion

on logThis(thisText)
	if logEnabled then current application's NSLog("%@", thisText)
end logThis

on speakWithMutedInput(stringToSpeak)
	try
		set volumeLevel to missing value
		tell current application
			set volumeLevel to input volume of (get volume settings)
			if volumeLevel is missing value then -- the current device has no input controls 
				my logThis("audio device has no input controls")
				say stringToSpeak with stopping current speech -- and waiting until completion
			else
				set volume input volume 0
				say stringToSpeak with stopping current speech and waiting until completion
				set volume input volume volumeLevel
			end if
		end tell
	on error errorMessage
		if volumeLevel is not missing value then
			tell current application
				try
					set volume input volume volumeLevel
				end try
			end tell
		end if
		beep
		my logThis(errorMessage)
	end try
end speakWithMutedInput




