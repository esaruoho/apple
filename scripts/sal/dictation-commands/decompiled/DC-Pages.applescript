use framework "Foundation"
use framework "AppKit"
use scripting additions

property logEnabled : true

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


(* ASSIST WITH TEMPLATE *)
on assistWithLocalizedTemplate(locKeyForTemplate)
	try
		set templateName to my getLocalizedStringForKey(locKeyForTemplate)
		if templateName is locKeyForTemplate then
			-- no localized template name
			error "NO_LOCALIZED_TEMPLATE_NAME"
		else
			assistWithTemplate(templateName)
		end if
	on error errorMessage number errorNumber
		my logThis(errorMessage)
		if errorNumber is not -128 then
			my displaySpokenErrorAlert(errorMessage, "com.apple.iWork.Pages")
		end if
		error number -128
	end try
end assistWithLocalizedTemplate

on assistWithTemplate(templateName)
	try
		tell application id "com.apple.iWork.Pages"
			activate
			set templateNames to the name of every template
			if templateName is not in templateNames then
				error "TEMPLATE_NOT_FOUND"
			end if
			my speakWithMutedInput(my getLocalizedStringForKey("OPEN_TEMPLATE") & templateName)
			set thisDocument to make new document with properties {document template:template templateName}
			tell thisDocument
				-- GET ALL TAGS
				set theseTags to the tag of every placeholder text
				
				-- FILTER FOR UNIQUE TAGS
				set uniqueTags to {}
				repeat with i from 1 to the count of theseTags
					set thisTag to item i of theseTags
					if thisTag is not in uniqueTags then
						set the end of uniqueTags to thisTag
					end if
				end repeat
				
				-- PROMPT USER FOR REPLACEMENT TEXT
				set uniqueTagsCount to the count of uniqueTags
				if uniqueTagsCount is greater than 0 then
					set locForPlaceholder to my getLocalizedStringForKey("PHRASE_FOR_PLACEHOLDER")
					set locForOF to my getLocalizedStringForKey("PHRASE_FOR_OF")
					set textReplacePrompt to my getLocalizedStringForKey("TEXT_REPLACE_PROMPT")
					set locButtonTitleCancel to my getLocalizedStringForKey("CANCEL_BUTTON_TITLE")
					set locButtonTitleSkip to my getLocalizedStringForKey("SKIP_BUTTON_TITLE")
					set locButtonTitleOK to my getLocalizedStringForKey("OK_BUTTON_TITLE")
					set locPlaceholderPrompt to my getLocalizedStringForKey("PLACEHOLDER_PROMPT")
				end if
				repeat with i from 1 to uniqueTagsCount
					set thisTag to item i of uniqueTags
					if the length of thisTag is less than 256 then
						set displayTag to thisTag
					else
						set displayTag to text 1 thru 256 of thisTag
					end if
					if i is 1 then
						set textToSpeak to locPlaceholderPrompt & (i as text) & space & locForOF & space & uniqueTagsCount
					else
						set textToSpeak to (i as text) & space & locForOF & space & uniqueTagsCount
					end if
					set sayUtil to "/usr/bin/say"
					set theTask to (current application's NSTask's launchedTaskWithLaunchPath:sayUtil arguments:{textToSpeak})
					set displayString to locForPlaceholder & space & i & space & locForOF & space & uniqueTagsCount & return & return & textReplacePrompt & return & return & displayTag
					try
						display dialog displayString default answer displayTag buttons {locButtonTitleCancel, locButtonTitleSkip, locButtonTitleOK} default button 3
						copy the result to {button returned:buttonPressed, text returned:replacementString}
						try
							theTask's terminate()
						end try
						if buttonPressed is "OK" then
							set (every placeholder text whose tag is thisTag) to replacementString
						end if
					on error
						try
							theTask's terminate()
						end try
						error number -128
					end try
				end repeat
				
				-- PROMPT USER FOR REPLACEMENT IMAGES
				set promptString to my getLocalizedStringForKey("CHOOSE_IMAGE_PROMPT")
				set textToSpeak to my getLocalizedStringForKey("CHOOSE_IMAGE_SPOKEN_PROMPT")
				repeat with i from 1 to the count of pages
					tell page i
						set theseImages to every image of it
						set imageCount to the count of theseImages
						repeat with q from 1 to the imageCount
							set thisImage to image q of it
							try
								set imageFileName to file name of thisImage
							on error
								set imageFileName to ""
							end try
							if locked of thisImage is false then -- placeholder images usually aren't locked!
								set sayUtil to "/usr/bin/say"
								set theTask to (current application's NSTask's launchedTaskWithLaunchPath:sayUtil arguments:{textToSpeak})
								--set position of thisImage to (the position of thisImage)
								set locked of thisImage to false
								tell application "System Events" to keystroke "0" using {command down, shift down}
								delay 1
								set thisImageFile to (choose file of type "public.image" with prompt (promptString & space & imageFileName) default location (path to pictures folder))
								set file name of thisImage to thisImageFile
							end if
						end repeat
					end tell
				end repeat
			end tell
		end tell
		tell application "System Events" to keystroke "0" using command down
		announceCompletion()
	on error errorMessage number errorNumber
		my logThis(errorMessage)
		if errorNumber is not -128 then
			my displaySpokenErrorAlert(errorMessage, "com.apple.iWork.Pages")
		end if
		error number -128
	end try
end assistWithTemplate

on createNewPagesWordProcessingDocument(bodyText, shouldActivate)
	set wordForBlank to getLocalizedStringForKey("WORD_FOR_BLANK")
	tell application id "com.apple.iWork.Pages"
		if shouldActivate is true then
			activate
		end if
		set thisDocument to make new document with properties {document template:template wordForBlank}
		tell thisDocument
			set body text to bodyText
		end tell
	end tell
end createNewPagesWordProcessingDocument

(* GRIDS *)

on createPagesLineGrid()
	try
		tell application id "com.apple.iWork.Pages"
			activate
			
			if not (exists document 1) then error "PAGES_NO_DOCUMENT"
			
			set confirmationSpokenPrompt to "OK, I’ll create a grid of lines, but first, please provide me with some details about this document and the grid."
			set confirmationPrompt to "To create a grid of lines on the front document, click the “Continue” button and provide the parameters for the grid to be created."
			say confirmationSpokenPrompt without waiting until completion
			display dialog confirmationPrompt buttons {"Cancel", "Continue"} default button 2 with title "CREATE GRID OF LINES"
			say " " with stopping current speech
			
			set paperSizeSpokenPrompt to "Select the paper size of the current document."
			set paperSizePrompt to "What is this document’s paper size?"
			say paperSizeSpokenPrompt without waiting until completion
			set chosenPageSize to (choose from list paperSizeNames with prompt paperSizePrompt default items (item 1 of paperSizeNames))
			say " " with stopping current speech
			if chosenPageSize is false then error number -128
			set chosenPageSize to chosenPageSize as string
			set thisPageDimensions to item (my indexOfItemInList(chosenPageSize, paperSizeNames)) of paperSizeDimensions
			
			set orientationSpokenPrompt to "Is the page orientation set to “landscape,” or “portrait?”"
			set orientationPrompt to "Is the page orientation set to landscape or portrait?"
			say orientationSpokenPrompt without waiting until completion
			display dialog orientationPrompt buttons {"Cancel", "Landscape", "Portrait"} default button 3
			if the button returned of the result is "Landscape" then
				set thisPageDimensions to the reverse of thisPageDimensions
			end if
			say " " with stopping current speech
			
			copy thisPageDimensions to {documentWidth, documentHeight}
			
			set topMarginSpokenPrompt to "Enter the size, in pixels, to use for the TOP page margin."
			set topMarginPrompt to "Enter the size of the TOP page margin to use (in pixels):"
			set topMarginHeight to my promptForIntegerValue(topMarginPrompt, topMarginSpokenPrompt, 0, documentHeight div 2, defaultTopMarginHeight)
			
			set bottomMarginSpokenPrompt to "For the BOTTOM margin."
			set bottomMarginPrompt to "Enter the size of the BOTTOM page margin to use (in pixels):"
			set bottomMarginHeight to my promptForIntegerValue(bottomMarginPrompt, bottomMarginSpokenPrompt, 0, documentHeight div 2, defaultBottomMarginHeight)
			
			set leftMarginSpokenPrompt to "And for the LEFT margin."
			set leftMarginPrompt to "Enter the size of the LEFT page margin to use (in pixels):"
			set leftMarginWidth to my promptForIntegerValue(leftMarginPrompt, leftMarginSpokenPrompt, 0, documentHeight div 2, defaultLeftMarginWidth)
			
			set rightMarginSpokenPrompt to "And for the RIGHT margin."
			set rightMarginPrompt to "Enter the size of RIGHT page margin to use (in pixels):"
			set rightMarginWidth to my promptForIntegerValue(rightMarginPrompt, rightMarginSpokenPrompt, 0, documentHeight div 2, defaultRightMarginWidth)
			
			set aSokenPrompt to "Do you want the grid to be comprised of horizontal lines, [[slnc 250]] vertical lines, [[slnc 250]] or both?"
			set aDisplayPrompt to "Do you want the grid to be comprised of horizontal lines, vertical lines, or both?"
			say aSokenPrompt without waiting until completion
			display dialog aDisplayPrompt buttons {"Horizontal", "Vertical", "Both"} default button 3
			set the gridType to the button returned of the result
			say " " with stopping current speech
			
			if gridType is in {"Both", "Vertical"} then
				set columnGutterSpokenPrompt to "Enter the space, in pixels, to put between the columns."
				set columnGutterPrompt to "Enter the space between COLUMNS (in pixels):"
				set columnGutterWidth to my promptForIntegerValue(columnGutterPrompt, columnGutterSpokenPrompt, 0, 100, defaultColumnGutterWidth)
			end if
			
			if gridType is in {"Both", "Horizontal"} then
				set rowGutterSpokenPrompt to "Enter the space, in pixels, to put between the rows."
				set rowGutterPrompt to "Enter the space between ROWS (in pixels):"
				set rowGutterHeight to my promptForIntegerValue(rowGutterPrompt, rowGutterSpokenPrompt, 0, 100, defaultRowGutterHeight)
			end if
			
			if gridType is in {"Both", "Vertical"} then
				set columnCountSpokenPrompt to "Enter the number of columns to be created."
				set columnCountPrompt to "Enter the number of columns to be created:"
				set columnCount to my promptForIntegerValue(columnCountPrompt, columnCountSpokenPrompt, 2, 20, defaultColumnCount)
			end if
			
			if gridType is in {"Both", "Horizontal"} then
				set rowCountSpokenPrompt to "Enter the number of rows to be created."
				set rowCountPrompt to "Enter the number of rows to be created:"
				set rowCount to my promptForIntegerValue(rowCountPrompt, rowCountSpokenPrompt, 2, 20, defaultRowCount)
			end if
			
			say "Thank you. Beginning grid creation."
			
			if gridType is in {"Both", "Vertical"} then
				set gutterCount to columnCount - 1
				
				set editableAreaWidth to documentWidth - leftMarginWidth - rightMarginWidth
				
				set editableColumnAreaWidth to editableAreaWidth - (gutterCount * columnGutterWidth)
				
				set editableSegmentWidth to editableColumnAreaWidth div columnCount
				
				tell document 1
					tell current page
						set startPointVertical to topMarginHeight
						set endPointVertical to documentHeight - bottomMarginHeight
						
						set thisstartPointHorizontal to leftMarginWidth
						set thisendPointHorizontal to leftMarginWidth
						
						set repeatCount to columnCount + 1 -- add a line for the side
						repeat with i from 1 to the repeatCount
							-- MAKE LINE
							set newLine to make new line
							tell newLine
								set start point to {thisstartPointHorizontal, startPointVertical}
								set end point to {thisendPointHorizontal, endPointVertical}
								set locked to true
							end tell
							
							if i is not 1 and i is not repeatCount then
								-- ADD GUTTER
								set thisstartPointHorizontal to thisstartPointHorizontal + columnGutterWidth
								set thisendPointHorizontal to thisendPointHorizontal + columnGutterWidth
								set newLine to make new line
								tell newLine
									set start point to {thisstartPointHorizontal, startPointVertical}
									set end point to {thisendPointHorizontal, endPointVertical}
									set locked to true
								end tell
								-- INCREMENT VERTICAL POSITION
								set thisstartPointHorizontal to thisstartPointHorizontal + editableSegmentWidth
								set thisendPointHorizontal to thisendPointHorizontal + editableSegmentWidth
							else
								-- INCREMENT VERTICAL POSITION
								set thisstartPointHorizontal to thisstartPointHorizontal + editableSegmentWidth
								set thisendPointHorizontal to thisendPointHorizontal + editableSegmentWidth
							end if
						end repeat
					end tell
				end tell
			end if
			
			if gridType is in {"Both", "Horizontal"} then
				set gutterCount to rowCount - 1
				
				set editableAreaHeight to documentHeight - topMarginHeight - bottomMarginHeight
				
				set editableRowAreaHeight to editableAreaHeight - (gutterCount * rowGutterHeight)
				
				set editableSegmentHeight to editableRowAreaHeight div rowCount
				
				tell document 1
					tell current page
						set startPointHorizontal to leftMarginWidth
						set endPointHorizontal to documentWidth - rightMarginWidth
						
						set thisStartPointVertical to topMarginHeight
						set thisEndPointVertical to topMarginHeight
						
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
								set thisStartPointVertical to thisStartPointVertical + rowGutterHeight
								set thisEndPointVertical to thisEndPointVertical + rowGutterHeight
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
			end if
		end tell
		announceCompletion()
	on error errorMessage number errorNumber
		say " " with stopping current speech
		if errorNumber is not -128 then
			my displaySpokenErrorAlert(errorMessage, "com.apple.iWork.Pages")
		end if
	end try
end createPagesLineGrid

on createPagesPageItemGrid()
	try
		tell application id "com.apple.iWork.Pages"
			activate
			
			if not (exists document 1) then error "PAGES_NO_DOCUMENT"
			
			set confirmationSpokenPrompt to "OK, I’ll create a grid of page items, but first, please provide me with some details about this document and the grid."
			set confirmationPrompt to "To create a grid of lines on the front document, click “Continue” and provide the parameters for the grid to be created."
			say confirmationSpokenPrompt without waiting until completion
			display dialog confirmationPrompt buttons {"Cancel", "Continue"} default button 2 with title "CREATE GRID OF PAGE ITEMS"
			say " " with stopping current speech
			
			set paperSizeSpokenPrompt to "Select the paper size of the current document."
			set paperSizePrompt to "What is this document’s paper size?"
			say paperSizeSpokenPrompt without waiting until completion
			set chosenPageSize to (choose from list paperSizeNames with prompt paperSizePrompt default items (item 1 of paperSizeNames))
			say " " with stopping current speech
			if chosenPageSize is false then error number -128
			set chosenPageSize to chosenPageSize as string
			set thisPageDimensions to item (my indexOfItemInList(chosenPageSize, paperSizeNames)) of paperSizeDimensions
			
			set orientationSpokenPrompt to "Is the page orientation set to “landscape,” or “portrait?”"
			set orientationPrompt to "Is the page orientation set to landscape or portrait?"
			say orientationSpokenPrompt without waiting until completion
			display dialog orientationPrompt buttons {"Cancel", "Landscape", "Portrait"} default button 3
			if the button returned of the result is "Landscape" then
				set thisPageDimensions to the reverse of thisPageDimensions
			end if
			say " " with stopping current speech
			
			copy thisPageDimensions to {documentWidth, documentHeight}
			
			set objectTypeSpokenPrompt to "Do you want the grid to be comprised of just images, [[slnc 250]] just text items, [[slnc 250]] or alternating rows of both image and text items."
			set objectTypePrompt to "Do you want to create just images, just text items, or alternating rows of both image and text items?"
			say objectTypeSpokenPrompt without waiting until completion
			display dialog objectTypePrompt buttons {"Images", "Text Items", "Both"} default button 3
			set the objectType to the button returned of the result
			say " " with stopping current speech
			
			set topMarginSpokenPrompt to "Enter the size, in pixels, to use for the TOP page margin."
			set topMarginPrompt to "Enter the size of the TOP page margin to use (in pixels):"
			set topMarginHeight to my promptForIntegerValue(topMarginPrompt, topMarginSpokenPrompt, 0, documentHeight div 2, defaultTopMarginHeight)
			
			set bottomMarginSpokenPrompt to "For the BOTTOM margin."
			set bottomMarginPrompt to "Enter the size of the BOTTOM page margin to use (in pixels):"
			set bottomMarginHeight to my promptForIntegerValue(bottomMarginPrompt, bottomMarginSpokenPrompt, 0, documentHeight div 2, defaultBottomMarginHeight)
			
			set leftMarginSpokenPrompt to "And for the LEFT margin."
			set leftMarginPrompt to "Enter the size of the LEFT page margin to use (in pixels):"
			set leftMarginWidth to my promptForIntegerValue(leftMarginPrompt, leftMarginSpokenPrompt, 0, documentHeight div 2, defaultLeftMarginWidth)
			
			set rightMarginSpokenPrompt to "And for the RIGHT margin."
			set rightMarginPrompt to "Enter the size of RIGHT page margin to use (in pixels):"
			set rightMarginWidth to my promptForIntegerValue(rightMarginPrompt, rightMarginSpokenPrompt, 0, documentHeight div 2, defaultRightMarginWidth)
			
			set columnGutterSpokenPrompt to "Enter the space, in pixels, to put between the columns of items."
			set columnGutterPrompt to "Enter the space between COLUMNS (in pixels):"
			set columnGutterWidth to my promptForIntegerValue(columnGutterPrompt, columnGutterSpokenPrompt, 0, 100, defaultColumnGutterWidth)
			
			set rowGutterSpokenPrompt to "And the space between the rows."
			set rowGutterPrompt to "Enter the space between ROWS (in pixels):"
			set rowGutterHeight to my promptForIntegerValue(rowGutterPrompt, rowGutterSpokenPrompt, 0, 100, defaultRowGutterHeight)
			
			set columnCountSpokenPrompt to "Enter the number of columns to be created."
			set columnCountPrompt to "Enter the number of columns to be created:"
			set columnCount to my promptForIntegerValue(columnCountPrompt, columnCountSpokenPrompt, 2, 20, defaultColumnCount)
			
			if objectType is "Both" then
				set rowCountForBothSpokenPrompt to "Since you’ve chosen to create alternating image and text rows, enter an even number, representing the total number of rows to be created."
				set rowCountForBothPrompt to "Since you’ve chosen to create alternating image and text rows, enter the total row count (including both image and text rows):" & return & return & "(This value must be an even number)"
				
				repeat
					set rowCount to my promptForIntegerValue(rowCountForBothPrompt, rowCountForBothSpokenPrompt, 2, 20, defaultRowCount)
					if rowCount mod 2 is 0 then
						exit repeat
					else
						beep
					end if
				end repeat
			else
				set rowCountSpokenPrompt to "Enter the number of rows to be created."
				set rowCountPrompt to "Enter the number of rows to be created:"
				set rowCount to my promptForIntegerValue(rowCountPrompt, rowCountSpokenPrompt, 2, 20, defaultRowCount)
			end if
			
			set pageIdentiferSpokenPrompt to "Do you want add identifiers to the page items?"
			set pageIdentiferPrompt to "Do you want add identifiers to the page items?"
			say pageIdentiferSpokenPrompt without waiting until completion
			display dialog pageIdentiferPrompt buttons {"Cancel", "No", "Yes"} default button 3
			if (the button returned of the result) is "Yes" then
				set shouldAddID to true
			else
				set shouldAddID to false
			end if
			say " " with stopping current speech
			
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
			
			say "Thank you. Beginning grid creation."
			
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
									set textItemCount to textItemCount + 1
									set placeholderText to "TEXT-" & textItemCount as text
									set aTextBox to make new text item with properties {width:shapeWidth, height:shapeHeight, position:{thisHorizontalOffset, thisVerticalOffset}}
									my addPlaceholderTextToTextItem(aTextBox, placeholderText)
								else
									set placeholderText to ""
									make new text item with properties {width:shapeWidth, height:shapeHeight, position:{thisHorizontalOffset, thisVerticalOffset}, object text:placeholderText}
								end if
							else if the objectType is "Both" then
								if i mod 2 is 0 then -- even row is text items
									if shouldAddID is true then
										set textItemCount to textItemCount + 1
										set placeholderText to "TEXT-" & textItemCount as text
										set aTextBox to make new text item with properties {width:shapeWidth, height:shapeHeight, position:{thisHorizontalOffset, thisVerticalOffset}}
										my addPlaceholderTextToTextItem(aTextBox, placeholderText)
									else
										set placeholderText to ""
										make new text item with properties {width:shapeWidth, height:shapeHeight, position:{thisHorizontalOffset, thisVerticalOffset}, object text:placeholderText}
									end if
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
		--tell script "DC-Workspace" to deleteItem(imageFile)
		announceCompletion()
	on error errorMessage number errorNumber
		say " " with stopping current speech
		if errorNumber is not -128 then
			my displaySpokenErrorAlert(errorMessage, "com.apple.iWork.Pages")
		end if
	end try
end createPagesPageItemGrid

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

on promptForLineDeletion()
	try
		tell application id "com.apple.iWork.Pages"
			activate
			
			if not (exists document 1) then error "PAGES_NO_DOCUMENT"
			
			display dialog "Delete lines from the current page?" buttons {"Cancel", "Delete All", "Delete Unlocked"} default button 1
			set deletionOption to the button returned of the result
			tell document 1
				tell current page
					if deletionOption is "Delete All" then
						set locked of every line to false
						delete every line
					else
						delete (every line whose locked is false)
					end if
				end tell
			end tell
		end tell
		announceCompletion()
	on error errorMessage number errorNumber
		if errorNumber is not -128 then
			my displaySpokenErrorAlert(errorMessage, "com.apple.iWork.Pages")
		end if
	end try
end promptForLineDeletion

on deleteAllLines(shouldConfirm)
	try
		tell application id "com.apple.iWork.Pages"
			activate
			
			if not (exists document 1) then error "PAGES_NO_DOCUMENT"
			
			if shouldConfirm is true then
				set confirmationPrompt to "Are you sure you want to delete all lines from the current page?" & return & return & "This action cannot be undone."
				set confirmationSpokenPrompt to "Are you sure you want to delete all lines from the current page?"
				say confirmationSpokenPrompt without waiting until completion
				display dialog confirmationPrompt with icon 2
				say " " with stopping current speech
			end if
			
			tell document 1
				tell current page
					set locked of every line to false
					delete every line
				end tell
			end tell
		end tell
		announceCompletion()
	on error errorMessage number errorNumber
		if errorNumber is not -128 then
			my displaySpokenErrorAlert(errorMessage, "com.apple.iWork.Pages")
		end if
	end try
end deleteAllLines

on deleteUnlockedLines(shouldConfirm)
	try
		tell application id "com.apple.iWork.Pages"
			activate
			
			if not (exists document 1) then error "PAGES_NO_DOCUMENT"
			
			if shouldConfirm is true then
				set confirmationPrompt to "Are you sure you want to delete all unlocked lines from the current page?" & return & return & "This action cannot be undone."
				set confirmationSpokenPrompt to "Are you sure you want to delete all unlocked lines from the current page?"
				say confirmationSpokenPrompt without waiting until completion
				display dialog confirmationPrompt with icon 2
				say " " with stopping current speech
			end if
			
			tell document 1
				tell current page
					delete (every line whose locked is false)
				end tell
			end tell
		end tell
		announceCompletion()
	on error errorMessage number errorNumber
		if errorNumber is not -128 then
			my displaySpokenErrorAlert(errorMessage, "com.apple.iWork.Pages")
		end if
	end try
end deleteUnlockedLines

on deleteLockedLines(shouldConfirm)
	try
		tell application id "com.apple.iWork.Pages"
			activate
			
			if not (exists document 1) then error "PAGES_NO_DOCUMENT"
			
			if shouldConfirm is true then
				set confirmationPrompt to "Are you sure you want to delete all locked lines from the current page?" & return & return & "This action cannot be undone."
				set confirmationSpokenPrompt to "Are you sure you want to delete all locked lines from the current page?"
				say confirmationSpokenPrompt without waiting until completion
				display dialog confirmationPrompt with icon 2
				say " " with stopping current speech
			end if
			
			tell document 1
				tell current page
					delete (every line whose locked is true)
				end tell
			end tell
		end tell
		announceCompletion()
	on error errorMessage number errorNumber
		if errorNumber is not -128 then
			my displaySpokenErrorAlert(errorMessage, "com.apple.iWork.Pages")
		end if
	end try
end deleteLockedLines




(* IMAGE FILE CREATION HANDLERS *)

on generatePlaceholderImageFileForPlacement(placeholderIndicator, sizeIndicator)
	copy deriveImageDimensions(sizeIndicator, placeholderIndicator) to {imageTargetWidth, imageTargetHeight}
	set targetImageFilePath to the POSIX path of (path to "cach" from user domain) & ("placeholder" & "-" & imageTargetWidth & "x" & imageTargetHeight & ".jpg") as text
	createCustomPlaceholderImageFile(imageTargetWidth, imageTargetHeight, targetImageFilePath, false)
	return (targetImageFilePath as POSIX file)
end generatePlaceholderImageFileForPlacement

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

on getLocalizedStringForKey(thisKey)
	set thisBundlePath to (path to me)
	return (localized string thisKey in bundle thisBundlePath)
end getLocalizedStringForKey

on announceCompletion()
	say my getLocalizedStringForKey("SUCCESSFUL_COMPLETION_PHRASE")
end announceCompletion

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

on logThis(thisText)
	if logEnabled then current application's NSLog("%@", thisText)
end logThis

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

