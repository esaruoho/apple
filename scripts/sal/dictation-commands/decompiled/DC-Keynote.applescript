use framework "Foundation"
use framework "AppKit"
use framework "EventKit"
use framework "CoreImage"
use framework "MapKit"
use framework "CoreLocation"
-- use framework "AddressBook"
use framework "CoreGraphics"
use scripting additions

property logEnabled : true

(* NEW DOCUMENTS *)

on newDefaultDocument()
	tell application id "com.apple.iWork.Keynote"
		activate
		if «class Plng» is true then
			tell document 1 to «event KnststoP»
		end if
		-- make a new document
		set newDocument to make new document
		-- resize document window to fit the screen
		set newDocID to the id of newDocument
		tell script "DC-Workspace" to resizeDocumentWindow("com.apple.iWork.Keynote", newDocID)
		my scaleLayoutViewToWrapSlide()
		-- store the JXA call to this handler
		set JXACommandString to "Library('DC-Keynote').newDefaultDocument();"
		tell script "DC-Support" to storeJXACommandString(JXACommandString)
		-- return a reference to the new Keynote document
		return newDocument
	end tell
end newDefaultDocument

on newDefaultDocumentStandard()
	tell application id "com.apple.iWork.Keynote"
		activate
		if «class Plng» is true then
			tell document 1 to «event KnststoP»
		end if
		-- make a new document
		set newDocument to make new document with properties {«class sitw»:1024, «class sith»:768}
		-- resize document window to fit the screen
		set newDocID to the id of newDocument
		tell script "DC-Workspace" to resizeDocumentWindow("com.apple.iWork.Keynote", newDocID)
		my scaleLayoutViewToWrapSlide()
		-- store the JXA call to this handler
		set JXACommandString to "Library('DC-Keynote').newDefaultDocumentStandard();"
		tell script "DC-Support" to storeJXACommandString(JXACommandString)
		-- return a reference to the new Keynote document
		return newDocument
	end tell
end newDefaultDocumentStandard

on newDefaultDocumentWide()
	tell application id "com.apple.iWork.Keynote"
		activate
		if «class Plng» is true then
			tell document 1 to «event KnststoP»
		end if
		-- make a new document
		set newDocument to make new document with properties {«class sitw»:1920, «class sith»:1080}
		-- resize document window to fit the screen
		set newDocID to the id of newDocument
		tell script "DC-Workspace" to resizeDocumentWindow("com.apple.iWork.Keynote", newDocID)
		my scaleLayoutViewToWrapSlide()
		-- store the JXA call to this handler
		set JXACommandString to "Library('DC-Keynote').newDefaultDocumentWide();"
		tell script "DC-Support" to storeJXACommandString(JXACommandString)
		-- return a reference to the new Keynote document
		return newDocument
	end tell
end newDefaultDocumentWide

on newDocumentUsingSpecifiedTemplate(templateName)
	tell application id "com.apple.iWork.Keynote"
		activate
		if «class Plng» is true then
			tell document 1 to «event KnststoP»
		end if
		set templateNames to the name of every «class Knth»
		ignoring case
			if templateName is in templateNames then
				-- make a new document
				set newDocument to make new document with properties {«class Kndt»:«class Knth» templateName}
				-- resize document window to fit the screen
				set newDocID to the id of newDocument
				tell script "DC-Workspace" to resizeDocumentWindow("com.apple.iWork.Keynote", newDocID)
				my scaleLayoutViewToWrapSlide()
				-- store the JXA call to this handler
				set JXACommandString to "Library('DC-Keynote').newDocumentUsingSpecifiedTemplate('" & templateName & "');"
				tell script "DC-Support" to storeJXACommandString(JXACommandString)
				-- return a reference to the new Keynote document
				return newDocument
			else
				set thisErrorMessage to (my getLocalizedStringForKey("KEYNOTE_THEME_DOES_NOT_EXIST") & templateName)
				my displaySpokenErrorAlert(thisErrorMessage, "com.apple.iWork.Keynote")
				error number -128
			end if
		end ignoring
	end tell
end newDocumentUsingSpecifiedTemplate

on newDocumentUsingSpecifiedParameters(dimensionsSpecifier, templateName)
	set localizedTermForKNStandardDimensions to my getLocalizedStringForKey("KEYNOTE_STANDARD_SPECIFIER")
	set localizedTermForKNWideDimensions to my getLocalizedStringForKey("KEYNOTE_WIDE_SPECIFIER")
	ignoring case
		if dimensionsSpecifier is localizedTermForKNStandardDimensions then
			set docDimensions to {1024, 768}
		else if dimensionsSpecifier is localizedTermForKNWideDimensions then
			set docDimensions to {1920, 1080}
		else
			set docDimensions to {1024, 768}
		end if
	end ignoring
	tell application id "com.apple.iWork.Keynote"
		activate
		if «class Plng» is true then
			tell document 1 to «event KnststoP»
		end if
		set templateNames to the name of every «class Knth»
		ignoring case
			if templateName is in templateNames then
				-- make new document
				copy docDimensions to {documentWidth, documentHeight}
				set newDocument to make new document with properties {«class Kndt»:«class Knth» templateName, «class sitw»:documentWidth, «class sith»:documentHeight}
				-- resize document window to fill screen
				set newDocID to the id of newDocument
				tell script "DC-Workspace" to resizeDocumentWindow("com.apple.iWork.Keynote", newDocID)
				my scaleLayoutViewToWrapSlide()
				-- store the JXA call to this handler
				set JXACommandString to "Library('DC-Keynote').newDocumentUsingSpecifiedParameters('" & dimensionsSpecifier & "', '" & templateName & "');"
				tell script "DC-Support" to storeJXACommandString(JXACommandString)
				-- return a reference to the new Keynote document
				return newDocument
			else
				set thisErrorMessage to (my getLocalizedStringForKey("KEYNOTE_THEME_DOES_NOT_EXIST") & templateName)
				my displaySpokenErrorAlert(thisErrorMessage, "com.apple.iWork.Keynote")
				error number -128
			end if
		end ignoring
	end tell
end newDocumentUsingSpecifiedParameters

(* THEME *)

on changeTemplateTo(localizedTemplatePlaceholder)
	try
		set templateName to my getLocalizedStringForKey(localizedTemplatePlaceholder)
		tell application id "com.apple.iWork.Keynote"
			activate
			if «class Plng» is true then
				tell document 1 to «event KnststoP»
			end if
			set templateNames to the name of every «class Knth»
			ignoring case
				if templateName is in templateNames then
					set «class Kndt» of front document to «class Knth» templateName
				else
					error (my getLocalizedStringForKey("KEYNOTE_THEME_DOES_NOT_EXIST") & templateName)
				end if
			end ignoring
		end tell
	on error errorMessage number errorNumber
		my displaySpokenErrorAlert(errorMessage, "com.apple.iWork.Keynote")
		error number -128
	end try
end changeTemplateTo

(* CLOSE DOCUMENTS *)

on closeFrontDocumentWithoutSaving()
	if running of application id "com.apple.iWork.Keynote" is true then
		tell application id "com.apple.iWork.Keynote"
			if the (count of documents) is not 0 then
				activate
				if «class Plng» is true then
					tell document 1 to «event KnststoP»
				end if
				close document 1 saving no
			end if
		end tell
	end if
	-- store the JXA call to this handler
	set JXACommandString to "Library('DC-Keynote').closeFrontDocumentWithoutSaving();"
	tell script "DC-Support" to storeJXACommandString(JXACommandString)
end closeFrontDocumentWithoutSaving

on closeAllDocumentsWithoutSaving()
	if running of application id "com.apple.iWork.Keynote" is true then
		tell application id "com.apple.iWork.Keynote"
			if the (count of documents) is not 0 then
				activate
				if «class Plng» is true then
					tell document 1 to «event KnststoP»
				end if
				close every document without saving
			end if
		end tell
	end if
	-- store the JXA call to this handler
	set JXACommandString to "Library('DC-Keynote').closeAllDocumentsWithoutSaving();"
	tell script "DC-Support" to storeJXACommandString(JXACommandString)
end closeAllDocumentsWithoutSaving

(* SHOW CURRENT KEYNOTE FILE *)
on showCurrentKeynoteFileOnDisk()
	try
		tell application id "com.apple.iWork.Keynote"
			if not (exists document 1) then
				error "KEYNOTE_NO_DOCUMENT"
			end if
			set thisFile to file of document 1
			if thisFile is missing value then
				error "UNSAVED_DOCUMENT"
			end if
			set thisFilePath to POSIX path of thisFile
			set thisFileURL to current application's NSURL's fileURLWithPath:thisFilePath
			set aSharedWorkspace to current application's NSWorkspace's sharedWorkspace
			aSharedWorkspace's activateFileViewerSelectingURLs:{thisFileURL}
		end tell
	on error errorMessage number errorNumber
		my displaySpokenErrorAlert(errorMessage, "com.apple.iWork.Keynote")
		error number -128
	end try
end showCurrentKeynoteFileOnDisk

(* SHOW FINDER INFO WINDOW FOR CURRENT KEYNOTE FILE *)
on showInfoWindowForCurrentKeynoteFileOnDisk()
	try
		tell application id "com.apple.iWork.Keynote"
			if not (exists document 1) then
				error "KEYNOTE_NO_DOCUMENT"
			end if
			set thisFile to file of document 1
			if thisFile is missing value then
				error "UNSAVED_DOCUMENT"
			end if
			set thisFilePath to POSIX path of thisFile
			set thisFileAlias to thisFilePath as POSIX file as alias
			set thisFileURL to current application's NSURL's fileURLWithPath:thisFilePath
			set aSharedWorkspace to current application's NSWorkspace's sharedWorkspace
			aSharedWorkspace's activateFileViewerSelectingURLs:{thisFileURL}
		end tell
		tell application id "com.apple.Finder"
			activate
			open information window of thisFileAlias
		end tell
	on error errorMessage number errorNumber
		my displaySpokenErrorAlert(errorMessage, "com.apple.iWork.Keynote")
		error number -128
	end try
end showInfoWindowForCurrentKeynoteFileOnDisk

(* FINDER SEARCH FOR PRESENTATION FILES WITH SIMILAR NAMES *)
on searchForSimilarlyNamedPresentations()
	try
		tell application id "com.apple.iWork.Keynote"
			if not (exists document 1) then
				error "KEYNOTE_NO_DOCUMENT"
			end if
			set thisFile to file of document 1
			if thisFile is missing value then
				error "UNSAVED_DOCUMENT"
			end if
			set thisFilePath to POSIX path of thisFile
		end tell
		-- get the name of the current presentation file
		set pathString to current application's NSString's stringWithString:thisFilePath
		set thePathNoExt to pathString's stringByDeletingPathExtension()
		set documentName to (thePathNoExt's lastPathComponent()) as string
		-- display a Finder search window
		set searchString to "kind:presentation" & space & quote & documentName & quote
		set aSharedWorkspace to current application's NSWorkspace's sharedWorkspace
		aSharedWorkspace's showSearchResultsForQueryString:searchString
	on error errorMessage number errorNumber
		my displaySpokenErrorAlert(errorMessage, "com.apple.iWork.Keynote")
		error number -128
	end try
end searchForSimilarlyNamedPresentations

(* DISPLAY LIST OF TYPEFACES USED IN THIS PRESENTATION *)
on displayFontListForCurrentPresentation()
	try
		tell application id "com.apple.iWork.Keynote"
			if not (exists document 1) then
				error "KEYNOTE_NO_DOCUMENT"
			end if
			set thisFile to file of document 1
			if thisFile is missing value then
				error "UNSAVED_DOCUMENT"
			end if
			set thisFilePath to POSIX path of thisFile
		end tell
		set queryResult to (do shell script "mdls -name kMDItemFonts " & quoted form of thisFilePath)
		
		set paragraphCount to the count of paragraphs of queryResult
		if paragraphCount is greater than or equal to 3 then
			set fontTitles to {}
			repeat with i from 2 to (the count of paragraphs of queryResult) - 1
				set thisParagraph to paragraph i of queryResult
				set the end of fontTitles to (its cleanUpFontListItem:thisParagraph)
			end repeat
			set fontTitlesArray to current application's NSArray's arrayWithArray:fontTitles
			set fontTitleBlock to (fontTitlesArray's componentsJoinedByString:linefeed) as string
			tell application id "com.apple.iWork.Keynote"
				display dialog fontTitleBlock buttons {"OK"} default button 1
			end tell
		else
			beep 2
		end if
	on error errorMessage number errorNumber
		my displaySpokenErrorAlert(errorMessage, "com.apple.iWork.Keynote")
		error number -128
	end try
end displayFontListForCurrentPresentation

(* SEARCH IN FINDER FOR ITEMS WITH THE SAME TAGS AS FRONTMOST PRESENTATION *)
on searchForItemsWithSameUserTagsAsFrontmostPresentation()
	try
		tell application id "com.apple.iWork.Keynote"
			if not (exists document 1) then
				error "KEYNOTE_NO_DOCUMENT"
			end if
			set thisFile to file of document 1
			if thisFile is missing value then
				error "UNSAVED_DOCUMENT"
			end if
			set thisFilePath to POSIX path of thisFile
			set docTitle to name of document 1
		end tell
		(*
		set queryResult to (do shell script "mdls -name kMDItemUserTags " & quoted form of thisFilePath)
		if queryResult is "kMDItemUserTags = (null)" then
			error "PRESENTION_FILE_HAS_NO_USER_TAGS"
		end if
		set paragraphCount to the count of paragraphs of queryResult
		if paragraphCount is greater than or equal to 3 then
			set fontTitles to {}
			repeat with i from 2 to (the count of paragraphs of queryResult) - 1
				set thisParagraph to paragraph i of queryResult
				set the end of fontTitles to quote & (its cleanUpFontListItem:thisParagraph) & quote
			end repeat
			set tagTitlesArray to current application's NSArray's arrayWithArray:fontTitles
			set tagTitleString to (tagTitlesArray's componentsJoinedByString:" ") as string
			set aSharedWorkspace to current application's NSWorkspace's sharedWorkspace
			aSharedWorkspace's showSearchResultsForQueryString:tagTitleString
		else
			beep 2
		end if
		*)
		
		## GET THE TAGS FOR THE FRONT DOCUMENT FILE
		set thisURL to current application's class "NSURL"'s fileURLWithPath:thisFilePath
		set {theResult, theTags, theError} to thisURL's getResourceValue:(reference) forKey:(current application's NSURLTagNamesKey) |error|:(reference)
		if theResult as boolean is false then error (theError's |localizedDescription|() as text)
		--if theTags = missing value then return {} -- because when there are none, it returns missing value
		--return theTags as list
		
		set docTitle to current application's class "NSString"'s stringWithString:docTitle
		set docTitle to docTitle's stringByDeletingPathExtension()
		set docTitle to (docTitle's stringByReplacingOccurrencesOfString:"\"" withString:"") as string
		
		if theTags is {} or theTags is missing value then
			set searchString to "name:\"" & docTitle & "\""
		else if (count of theTags) is 1 then
			set searchString to "name:\"" & docTitle & "\"" & " OR " & "tag:\"" & (theTags as string) & "\""
		else
			set thisArray to current application's class "NSArray"'s arrayWithArray:theTags
			set searchString to "name:\"" & docTitle & "\"" & " OR " & "tag:\"" & (thisArray's componentsJoinedByString:"\" OR tag:\"") as string
		end if
		
		## DO SEARCH IN FINDER
		set aWorkspace to current application's NSWorkspace's sharedWorkspace
		aWorkspace's showSearchResultsForQueryString:searchString
		
	on error errorMessage number errorNumber
		my displaySpokenErrorAlert(errorMessage, "com.apple.iWork.Keynote")
		error number -128
	end try
end searchForItemsWithSameUserTagsAsFrontmostPresentation

(* SEARCH IN FINDER FOR ITEMS WITH THE SAME TAGS AS FRONTMOST PRESENTATION *)
on searchWithSpotlightForImageFilesWithSameUserTagsAsFrontmostPresentation()
	try
		tell application id "com.apple.iWork.Keynote"
			if not (exists document 1) then
				error "KEYNOTE_NO_DOCUMENT"
			end if
			set thisFile to file of document 1
			if thisFile is missing value then
				error "UNSAVED_DOCUMENT"
			end if
			set thisFilePath to POSIX path of thisFile
			set docTitle to name of document 1
		end tell
		(*
		set queryResult to (do shell script "mdls -name kMDItemUserTags " & quoted form of thisFilePath)
		if queryResult is "kMDItemUserTags = (null)" then
			error "PRESENTION_FILE_HAS_NO_USER_TAGS"
		end if
		set paragraphCount to the count of paragraphs of queryResult
		if paragraphCount is greater than or equal to 3 then
			set fontTitles to {}
			repeat with i from 2 to (the count of paragraphs of queryResult) - 1
				set thisParagraph to paragraph i of queryResult
				set the end of fontTitles to quote & (its cleanUpFontListItem:thisParagraph) & quote
			end repeat
			set tagTitlesArray to current application's NSArray's arrayWithArray:fontTitles
			set tagTitleString to (tagTitlesArray's componentsJoinedByString:" ") as string
			set aSharedWorkspace to current application's NSWorkspace's sharedWorkspace
			aSharedWorkspace's showSearchResultsForQueryString:tagTitleString
		else
			beep 2
		end if
		*)
		
		## GET THE TAGS FOR THE FRONT DOCUMENT FILE
		set thisURL to current application's class "NSURL"'s fileURLWithPath:thisFilePath
		set {theResult, theTags, theError} to thisURL's getResourceValue:(reference) forKey:(current application's NSURLTagNamesKey) |error|:(reference)
		if theResult as boolean is false then error (theError's |localizedDescription|() as text)
		--if theTags = missing value then return {} -- because when there are none, it returns missing value
		--return theTags as list
		
		set docTitle to current application's class "NSString"'s stringWithString:docTitle
		set docTitle to docTitle's stringByDeletingPathExtension()
		set docTitle to (docTitle's stringByReplacingOccurrencesOfString:"\"" withString:"") as string
		
		if theTags is {} or theTags is missing value then
			set searchString to "kind:image"
		else if (count of theTags) is 1 then
			set searchString to "kind:image" & " AND " & "tag:\"" & (theTags as string) & "\""
		else
			set thisArray to current application's class "NSArray"'s arrayWithArray:theTags
			set searchString to "kind:image" & " AND " & "tag:\"" & (thisArray's componentsJoinedByString:"\" OR tag:\"") as string
		end if
		
		tell application "Keynote Creator Studio"
			activate
			delay 0.5
			tell application "System Events"
				-- tell process "Keynote"
				keystroke space using command down
				delay 0.5
				-- set searchString to "images tagged with \"" & specifiedTag "\”"
				keystroke searchString
				-- end tell
			end tell
		end tell
		
	on error errorMessage number errorNumber
		my displaySpokenErrorAlert(errorMessage, "com.apple.iWork.Keynote")
		error number -128
	end try
end searchWithSpotlightForImageFilesWithSameUserTagsAsFrontmostPresentation

on cleanUpFontListItem:someText
	set theString to current application's NSString's stringWithString:someText
	set stringLength to theString's |length|()
	set theString to theString's stringByReplacingOccurrencesOfString:"\"" withString:"" --options:(current application's NSRegularExpressionSearch) range:{location:0, |length|:stringLength}
	set theString to theString's stringByReplacingOccurrencesOfString:"," withString:"" --options:(current application's NSRegularExpressionSearch) range:{location:0, |length|:stringLength}
	set theWhiteSet to current application's NSCharacterSet's whitespaceAndNewlineCharacterSet()
	set theString to theString's stringByTrimmingCharactersInSet:theWhiteSet
	return theString as text
end cleanUpFontListItem:

on searchWithSpotlightForImagesWithSpecifiedTag(specifiedTag)
	tell application "Keynote Creator Studio"
		activate
		delay 0.5
		tell application "System Events"
			tell process "Keynote"
				keystroke space using command down
				delay 0.5
				-- search for images with the tag “national parks”
				set searchString to "kind:image tag:\"" & specifiedTag & "\""
				-- set searchString to "images tagged with \"" & specifiedTag "\”"
				keystroke searchString
			end tell
		end tell
	end tell
end searchWithSpotlightForImagesWithSpecifiedTag

(* SLIDE PROPERTIES *)

on setShowingOfCurrentSlideTitle(showingBooleanValue)
	set showingBooleanValue to returnBooleanValue(showingBooleanValue)
	tell application id "com.apple.iWork.Keynote"
		if not (exists document 1) then
			my displaySpokenErrorAlert("KEYNOTE_NO_DOCUMENT", "com.apple.iWork.Keynote")
			error number -128
		end if
		tell front document
			tell the «class crsl»
				set «class Ktsh» to showingBooleanValue
			end tell
		end tell
	end tell
end setShowingOfCurrentSlideTitle

on setShowingOfCurrentSlideBody(showingBooleanValue)
	set showingBooleanValue to returnBooleanValue(showingBooleanValue)
	tell application id "com.apple.iWork.Keynote"
		if not (exists document 1) then
			my displaySpokenErrorAlert("KEYNOTE_NO_DOCUMENT", "com.apple.iWork.Keynote")
			error number -128
		end if
		tell front document
			tell the «class crsl»
				set «class Kbsh» to showingBooleanValue
			end tell
		end tell
	end tell
end setShowingOfCurrentSlideBody

on setAllSlideNumbersShowing(showingBooleanValue)
	set showingBooleanValue to returnBooleanValue(showingBooleanValue)
	tell application id "com.apple.iWork.Keynote"
		if not (exists document 1) then
			my displaySpokenErrorAlert("KEYNOTE_NO_DOCUMENT", "com.apple.iWork.Keynote")
			error number -128
		end if
		tell front document
			set «class Knsh» to showingBooleanValue
		end tell
	end tell
end setAllSlideNumbersShowing


(* SLIDE ACTIONS *)

on appendBlankSlide()
	tell application id "com.apple.iWork.Keynote"
		try
			activate
			if «class Plng» is true then
				beep
				return false
			else
				if not (exists document 1) then
					error "KEYNOTE_NO_DOCUMENT"
				end if
			end if
			set masterSlideTitleForBlank to my getLocalizedStringForKey("KEYNOTE_BLANK_MASTER_TITLE") -- (localized string "KEYNOTE_BLANK_MASTER_TITLE" in bundle thisBundlePath)
			set masterSlideTitles to the name of every «class KnMs» of document 1
			if masterSlideTitleForBlank is in masterSlideTitles then
				tell front document
					make new «class KnSd» with properties {«class smas»:«class KnMs» masterSlideTitleForBlank}
				end tell
			else
				error "KEYNOTE_BLANK_MASTER_DOES_NOT_EXIST"
			end if
			-- store the JXA call to this handler
			set JXACommandString to "Library('DC-Keynote').appendBlankSlide();"
			tell script "DC-Support" to storeJXACommandString(JXACommandString)
		on error errorMessage number errorNumber
			if errorNumber is not -128 then
				my displaySpokenErrorAlert(errorMessage, "com.apple.iWork.Keynote")
			end if
			error number -128
		end try
	end tell
end appendBlankSlide

on insertBlankSlide()
	tell application id "com.apple.iWork.Keynote"
		try
			activate
			if «class Plng» is true then
				beep
				return false
			else
				if not (exists document 1) then
					error "KEYNOTE_NO_DOCUMENT"
				end if
			end if
			set masterSlideTitleForBlank to my getLocalizedStringForKey("KEYNOTE_BLANK_MASTER_TITLE")
			set masterSlideTitles to the name of every «class KnMs» of document 1
			if masterSlideTitleForBlank is in masterSlideTitles then
				tell front document
					set currentSlide to (get «class crsl»)
					make new «class KnSd» at after currentSlide with properties {«class smas»:«class KnMs» masterSlideTitleForBlank}
				end tell
			else
				error "KEYNOTE_BLANK_MASTER_DOES_NOT_EXIST"
			end if
			-- store the JXA call to this handler
			set JXACommandString to "Library('DC-Keynote').insertBlankSlide();"
			tell script "DC-Support" to storeJXACommandString(JXACommandString)
		on error errorMessage number errorNumber
			if errorNumber is not -128 then
				my displaySpokenErrorAlert(errorMessage, "com.apple.iWork.Keynote")
			end if
			error number -128
		end try
	end tell
end insertBlankSlide

on insertDefaultSlide()
	tell application id "com.apple.iWork.Keynote"
		try
			activate
			if «class Plng» is true then
				beep
				return false
			else
				if not (exists document 1) then
					error "KEYNOTE_NO_DOCUMENT"
				end if
			end if
			tell front document
				set currentSlide to (get «class crsl»)
				make new «class KnSd» at after currentSlide
			end tell
			-- store the JXA call to this handler
			set JXACommandString to "Library('DC-Keynote').insertDefaultSlide();"
			tell script "DC-Support" to storeJXACommandString(JXACommandString)
		on error errorMessage number errorNumber
			if errorNumber is not -128 then
				my displaySpokenErrorAlert(errorMessage, "com.apple.iWork.Keynote")
			end if
			error number -128
		end try
	end tell
end insertDefaultSlide

on setMasterOfCurrentSlide(localizedKeyForMasterTitle)
	set targetMasterSlideTitle to getLocalizedStringForKey(localizedKeyForMasterTitle)
	changeMasterOfCurrentSlide(targetMasterSlideTitle)
end setMasterOfCurrentSlide

on changeMasterOfCurrentSlide(targetMasterSlideTitle)
	tell application id "com.apple.iWork.Keynote"
		try
			activate
			if «class Plng» is true then
				beep
				return false
			else
				if not (exists document 1) then
					error "KEYNOTE_NO_DOCUMENT"
				end if
			end if
			
			set masterSlideTitles to the name of every «class KnMs» of document 1
			--> {"Title & Subtitle", "Photo - Horizontal", "Title - Center", "Photo - Vertical", "Title - Top", "Title & Bullets", "Title, Bullets & Photo", "Bullets", "Photo - 3 Up", "Quote", "Photo", "Blank"}
			if masterSlideTitles contains targetMasterSlideTitle then
				tell front document
					set the «class smas» of the «class crsl» to «class KnMs» targetMasterSlideTitle
				end tell
				return true
			else
				error ((my getLocalizedStringForKey("KEYNOTE_MASTER_DOES_NOT_EXIST")) & targetMasterSlideTitle)
			end if
			-- store the JXA call to this handler
			set JXACommandString to "Library('DC-Keynote').changeMasterOfCurrentSlide('" & targetMasterSlideTitle & "');"
			tell script "DC-Support" to storeJXACommandString(JXACommandString)
		on error errorMessage number errorNumber
			if errorNumber is not -128 then
				my displaySpokenErrorAlert(errorMessage, "com.apple.iWork.Keynote")
			end if
			error number -128
		end try
	end tell
end changeMasterOfCurrentSlide

on applyMasterSlideChosenFromList()
	tell application id "com.apple.iWork.Keynote"
		if not (exists document 1) then
			my displaySpokenErrorAlert("KEYNOTE_NO_DOCUMENT", "com.apple.iWork.Keynote")
			error number -128
		end if
		activate
		tell front document
			set masterSlideNames to the name of every «class KnMs»
			set masterSlideNames to my sortListOfStrings(masterSlideNames)
			set defaultItem to item 1 of masterSlideNames
			set dialogResult to (choose from list masterSlideNames default items {defaultItem})
			if dialogResult is false then
				error number -128
			else
				set masterSlideTitle to item 1 of dialogResult
			end if
			set the «class smas» of the «class crsl» to «class KnMs» masterSlideTitle
		end tell
	end tell
end applyMasterSlideChosenFromList

on sortListOfStrings(theList)
	set theArray to current application's NSArray's arrayWithArray:theList
	set theArray to theArray's sortedArrayUsingSelector:"localizedStandardCompare:"
	return theArray as list
end sortListOfStrings

on moveCurrentSlideToEndOfSlides()
	tell application id "com.apple.iWork.Keynote"
		try
			if the (count of documents) is 0 then
				error "KEYNOTE_NO_DOCUMENT"
			end if
			tell front document
				move (get «class crsl») to after last «class KnSd»
			end tell
			delay 1
			-- store the JXA call to this handler
			set JXACommandString to "Library('DC-Keynote').presentationSaveInDocumentsFolderUsingFirstSlideTitle();"
			tell script "DC-Support" to storeJXACommandString(JXACommandString)
			my announceCompletion()
		on error errorMessage number errorNumber
			if errorNumber is not -128 then
				my displaySpokenErrorAlert(errorMessage, "com.apple.iWork.Keynote")
			end if
			error number -128
		end try
	end tell
end moveCurrentSlideToEndOfSlides

on scaleLayoutViewToWrapSlide()
	tell application id "com.apple.iWork.Keynote"
		activate
		if «class Plng» is true then
			beep
			error number -128
		else
			if not (exists document 1) then
				error "KEYNOTE_NO_DOCUMENT"
			end if
		end if
		try
			tell front document
				set aWidth to the «class sitw» of it
				set aHeight to the «class sith» of it
				tell «class crsl»
					set aShape to make new «class sshp» with properties {«class sitw»:aWidth, «class sith»:aHeight, «class sipo»:{0, 0}}
				end tell
				tell application "System Events"
					keystroke "0" using {command down, shift down}
				end tell
				tell current application
					do shell script "sleep 1.0"
				end tell
				delete aShape
			end tell
		on error errorMessage number errorNumber
			if errorNumber is not -128 then
				my displaySpokenErrorAlert(errorMessage, "com.apple.iWork.Keynote")
			end if
			error number -128
		end try
	end tell
end scaleLayoutViewToWrapSlide

on scaleLayoutViewToWrapSelectedSlideItems()
	try
		tell application id "com.apple.iWork.Keynote"
			activate
			if «class Plng» is true then
				beep
				error number -128
			else
				if not (exists document 1) then
					error "KEYNOTE_NO_DOCUMENT"
				end if
			end if
		end tell
		try
			tell application "System Events"
				keystroke "0" using {command down, shift down}
			end tell
		end try
	on error errorMessage number errorNumber
		if errorNumber is not -128 then
			my displaySpokenErrorAlert(errorMessage, "com.apple.iWork.Keynote")
		end if
		error number -128
	end try
end scaleLayoutViewToWrapSelectedSlideItems


(* SLIDE MANIPULATION ROUTINES *)
on duplicateSlideAndApplyMagicMoveToSourceSlide(useAutomaticTransition)
	tell application id "com.apple.iWork.Keynote"
		activate
		if «class Plng» is true then
			tell the front document to «event KnststoP»
		else
			if not (exists document 1) then
				my displaySpokenErrorAlert("KEYNOTE_NO_DOCUMENT", "com.apple.iWork.Keynote")
				error number -128
			end if
		end if
		tell front document
			set slide1 to «class crsl» of it
			set slide2 to duplicate slide1 to after slide1
			set the «class strn» of slide1 to {«class xeft»:«constant tefftmjv», «class xdur»:1.25, «class xdly»:0, «class xaut»:useAutomaticTransition}
		end tell
	end tell
end duplicateSlideAndApplyMagicMoveToSourceSlide

on duplicateCurrentSlideToAfterCurrentSlide()
	tell application id "com.apple.iWork.Keynote"
		activate
		if «class Plng» is true then
			tell the front document to «event KnststoP»
		else
			if not (exists document 1) then
				my displaySpokenErrorAlert("KEYNOTE_NO_DOCUMENT", "com.apple.iWork.Keynote")
				error number -128
			end if
		end if
		tell front document
			set slide1 to «class crsl» of it
			set slide2 to duplicate slide1 to after slide1
		end tell
	end tell
end duplicateCurrentSlideToAfterCurrentSlide

on createNewDocumentWithCurrentSlide()
	tell application id "com.apple.iWork.Keynote"
		activate
		if «class Plng» is true then
			tell the front document to «event KnststoP»
		else
			if not (exists document 1) then
				my displaySpokenErrorAlert("KEYNOTE_NO_DOCUMENT", "com.apple.iWork.Keynote")
				error number -128
			end if
		end if
		tell the front document
			set currentSlide to «class crsl»
			set currentTheme to the «class Kndt»
			set documentWidth to its «class sitw»
			set documentHeight to its «class sith»
			duplicate currentSlide to after currentSlide
		end tell
		set newDocument to make new document with properties {«class Kndt»:currentTheme, «class sitw»:documentWidth, «class sith»:documentHeight}
		move currentSlide to after «class KnSd» 1 of newDocument
		delete «class KnSd» 1 of newDocument
	end tell
end createNewDocumentWithCurrentSlide

(* PANORAMIC SEQUENCE *)

on createPanoramicSequenceForCurrentSlide(transitionPanDuration, shouldPlay)
	try
		(* TRANSITION PROPERTIES *)
		set transitionInOutDuration to 4
		-- set transitionPanDuration to 10
		set transitionInOutDelay to 1
		
		tell application id "com.apple.iWork.Keynote"
			activate
			if not (exists document 1) then
				my displaySpokenErrorAlert("KEYNOTE_NO_DOCUMENT", "com.apple.iWork.Keynote")
				error number -128
			end if
			if «class Plng» is true then tell front document to «event KnststoP»
			tell front document
				if the (count of every «class imag» of the «class crsl») is not 1 then
					error "SLIDE_MUST_CONTAIN_ONLY_ONE_IMAGE"
				end if
				
				-- get dimensions of the current document
				set documentHeight to its «class sith»
				set documentWidth to its «class sitw»
				
				(* DUPLICATE SOURCE SLIDE AND ADJUST IMAGE POSITION FOR PANO *)
				set sourceSlide to (get «class crsl»)
				set sourceSlideTransitionProperties to «class strn» of sourceSlide
				
				-- duplicate the slide to pano
				duplicate (get «class crsl») to after (get «class crsl»)
				
				set panoStartSlide to (get «class crsl»)
				-- size the image to fill height and align to the left
				tell «class crsl»
					tell last «class imag»
						set «class sith» to documentHeight
						set «class sipo» to {0, 0}
					end tell
				end tell
				
				duplicate (get «class crsl») to after (get «class crsl»)
				set panoEndSlide to (get «class crsl»)
				
				-- adjust the image position to align right
				tell «class crsl»
					tell last «class imag»
						set imageWidth to its «class sitw»
						set «class sipo» to {documentWidth - imageWidth, 0}
					end tell
				end tell
				
				duplicate sourceSlide to after panoEndSlide
				
				set panoCompleteSlide to (get «class crsl»)
				
				(* APPLY TRANSISTIONS *)
				
				tell sourceSlide
					-- set transition to Magic Move
					set the «class strn» to ¬
						{«class xeft»:«constant tefftmjv» ¬
							, «class xdur»:transitionInOutDuration ¬
							, «class xdly»:transitionInOutDelay ¬
							, «class xaut»:true}
				end tell
				
				tell panoStartSlide
					-- set transition to Magic Move
					set the «class strn» to ¬
						{«class xeft»:«constant tefftmjv» ¬
							, «class xdur»:transitionPanDuration ¬
							, «class xdly»:0 ¬
							, «class xaut»:true}
				end tell
				
				tell panoEndSlide
					-- set transition to Magic Move
					set the «class strn» to ¬
						{«class xeft»:«constant tefftmjv» ¬
							, «class xdur»:transitionInOutDuration ¬
							, «class xdly»:transitionInOutDelay ¬
							, «class xaut»:true}
				end tell
				
				tell panoCompleteSlide
					-- set the transition properties to sourceSlideTransitionProperties
					set the «class strn» to {«class xeft»:«constant tefftdis», «class xdly»:0, «class xdur»:3}
				end tell
				
			end tell
			
			my announceCompletion()
			
			if shouldPlay is true then
				«event KnstplaY» front document given «class kfro»:sourceSlide
			end if
		end tell
	on error errorMessage number errorNumber
		if errorNumber is not -128 then
			my displaySpokenErrorAlert(errorMessage, "com.apple.iWork.Keynote")
		end if
		error number -128
	end try
end createPanoramicSequenceForCurrentSlide

(* SLIDE TRANSISTION ROUTINES *)

on resetTransitionPropertiesForCurrentSlide()
	tell application id "com.apple.iWork.Keynote"
		activate
		if «class Plng» is true then
			tell the front document to «event KnststoP»
		else
			if not (exists document 1) then
				my displaySpokenErrorAlert("KEYNOTE_NO_DOCUMENT", "com.apple.iWork.Keynote")
				error number -128
			end if
		end if
		tell front document
			set the «class strn» of «class crsl» to {«class xeft»:«constant tefftnil», «class xdur»:1.5, «class xdly»:0, «class xaut»:false}
		end tell
	end tell
	-- store the JXA call to this handler
	set JXACommandString to "Library('DC-Keynote').resetTransitionPropertiesForCurrentSlide();"
	tell script "DC-Support" to storeJXACommandString(JXACommandString)
end resetTransitionPropertiesForCurrentSlide

on resetTransitionPropertiesForEverySlide()
	tell application id "com.apple.iWork.Keynote"
		activate
		if «class Plng» is true then
			tell the front document to «event KnststoP»
		else
			if not (exists document 1) then
				my displaySpokenErrorAlert("KEYNOTE_NO_DOCUMENT", "com.apple.iWork.Keynote")
				error number -128
			end if
		end if
		tell front document
			set the «class strn» of every «class KnSd» whose «class Kskp» is false to {«class xeft»:«constant tefftnil», «class xdur»:1.5, «class xdly»:0, «class xaut»:false}
		end tell
	end tell
	-- store the JXA call to this handler
	set JXACommandString to "Library('DC-Keynote').resetTransitionPropertiesForEverySlide();"
	tell script "DC-Support" to storeJXACommandString(JXACommandString)
end resetTransitionPropertiesForEverySlide

on removeTransitionEffectFromEverySlide()
	tell application id "com.apple.iWork.Keynote"
		activate
		if «class Plng» is true then
			tell the front document to «event KnststoP»
		else
			if not (exists document 1) then
				my displaySpokenErrorAlert("KEYNOTE_NO_DOCUMENT", "com.apple.iWork.Keynote")
				error number -128
			end if
		end if
		tell front document
			set the «class strn» of every «class KnSd» whose «class Kskp» is false to {«class xeft»:«constant tefftnil»}
		end tell
	end tell
	-- store the JXA call to this handler
	set JXACommandString to "Library('DC-Keynote').removeTransitionEffectFromEverySlide();"
	tell script "DC-Support" to storeJXACommandString(JXACommandString)
end removeTransitionEffectFromEverySlide

on applyDissolveTransitionEffectToEverySlide(durationValue)
	tell application id "com.apple.iWork.Keynote"
		activate
		if «class Plng» is true then
			tell the front document to «event KnststoP»
		else
			if not (exists document 1) then
				my displaySpokenErrorAlert("KEYNOTE_NO_DOCUMENT", "com.apple.iWork.Keynote")
				error number -128
			end if
		end if
		tell front document
			set the «class strn» of every «class KnSd» whose «class Kskp» is false to {«class xeft»:«constant tefftdis», «class xdly»:0, «class xdur»:durationValue}
		end tell
	end tell
	-- store the JXA call to this handler
	set JXACommandString to "Library('DC-Keynote').applyDissolveTransitionEffectToEverySlide(" & durationValue & ");"
	tell script "DC-Support" to storeJXACommandString(JXACommandString)
end applyDissolveTransitionEffectToEverySlide

on applyDissolveTransitionEffectToCurrentSlide(durationValue)
	tell application id "com.apple.iWork.Keynote"
		activate
		if «class Plng» is true then
			tell the front document to «event KnststoP»
		else
			if not (exists document 1) then
				my displaySpokenErrorAlert("KEYNOTE_NO_DOCUMENT", "com.apple.iWork.Keynote")
				error number -128
			end if
		end if
		tell front document
			set the «class strn» of «class crsl» to {«class xeft»:«constant tefftdis», «class xdly»:0, «class xdur»:durationValue}
		end tell
	end tell
	-- store the JXA call to this handler
	set JXACommandString to "Library('DC-Keynote').applyDissolveTransitionEffectToCurrentSlide(" & durationValue & ");"
	tell script "DC-Support" to storeJXACommandString(JXACommandString)
end applyDissolveTransitionEffectToCurrentSlide

on applyMagicMoveTransitionEffectToCurrentSlide(durationValue)
	tell application id "com.apple.iWork.Keynote"
		activate
		if «class Plng» is true then
			tell the front document to «event KnststoP»
		else
			if not (exists document 1) then
				my displaySpokenErrorAlert("KEYNOTE_NO_DOCUMENT", "com.apple.iWork.Keynote")
				error number -128
			end if
		end if
		tell front document
			set the «class strn» of «class crsl» to {«class xeft»:«constant tefftmjv», «class xdly»:0, «class xdur»:durationValue}
		end tell
	end tell
	-- store the JXA call to this handler
	set JXACommandString to "Library('DC-Keynote').applyMagicMoveTransitionEffectToCurrentSlide(" & durationValue & ");"
	tell script "DC-Support" to storeJXACommandString(JXACommandString)
end applyMagicMoveTransitionEffectToCurrentSlide

on setAutomaticTransition(booleanValue)
	tell application id "com.apple.iWork.Keynote"
		activate
		if «class Plng» is true then
			tell the front document to «event KnststoP»
		else
			if not (exists document 1) then
				my displaySpokenErrorAlert("KEYNOTE_NO_DOCUMENT", "com.apple.iWork.Keynote")
				error number -128
			end if
		end if
		tell front document
			set the «class strn» of «class crsl» to {«class xaut»:booleanValue}
		end tell
	end tell
	-- store the JXA call to this handler
	set JXACommandString to "Library('DC-Keynote').setAutomaticTransition(" & booleanValue & ");"
	tell script "DC-Support" to storeJXACommandString(JXACommandString)
end setAutomaticTransition

on setAutomaticTransitionForAllSlides(booleanValue)
	tell application id "com.apple.iWork.Keynote"
		activate
		if «class Plng» is true then
			tell the front document to «event KnststoP»
		else
			if not (exists document 1) then
				my displaySpokenErrorAlert("KEYNOTE_NO_DOCUMENT", "com.apple.iWork.Keynote")
				error number -128
			end if
		end if
		tell front document
			set the «class strn» of every «class KnSd» whose «class Kskp» is false to {«class xaut»:booleanValue}
		end tell
	end tell
	-- store the JXA call to this handler
	set JXACommandString to "Library('DC-Keynote').setAutomaticTransitionForAllSlides(" & booleanValue & ");"
	tell script "DC-Support" to storeJXACommandString(JXACommandString)
end setAutomaticTransitionForAllSlides


(* SLIDE TEXT ITEMS *)

on enterDefautBodyItem()
	tell application id "com.apple.iWork.Keynote"
		try
			activate
			if «class Plng» is true then
				beep
				return false
			else
				if not (exists document 1) then
					error "KEYNOTE_NO_DOCUMENT"
				end if
			end if
			tell front document
				tell «class crsl»
					if «class Kbsh» is false then
						beep
						error number -128
					else
						if «class pLck» of «class sdbi» is true then
							tell script "DC-Assistive-Keynote" to playUnlockingSound()
							(*
							tell current application
								say "unlocking"
							end tell
							*)
						end if
						-- select the default body item
						-- set position of default body item to position of default body item
						set «class pLck» of «class sdbi» to false
						-- press the Enter key
						tell application "System Events" to key code 76
					end if
				end tell
			end tell
			-- store the JXA call to this handler
			set JXACommandString to "Library('DC-Keynote').enterDefautBodyItem();"
			tell script "DC-Support" to storeJXACommandString(JXACommandString)
			my speakWithMutedInput(my getLocalizedStringForKey("READY_PHRASE"))
			return true
		on error errorMessage number errorNumber
			if errorNumber is not -128 then
				my displaySpokenErrorAlert(errorMessage, "com.apple.iWork.Keynote")
			end if
			error number -128
		end try
	end tell
end enterDefautBodyItem

on selectDefaultBodyItem()
	tell application id "com.apple.iWork.Keynote"
		try
			activate
			if «class Plng» is true then
				beep
				return false
			else
				if not (exists document 1) then
					error "KEYNOTE_NO_DOCUMENT"
				end if
			end if
			tell front document
				tell «class crsl»
					if «class Kbsh» is false then
						beep
						error number -128
					else
						-- select the default body item
						-- set position of default body item to position of default body item
						set «class pLck» of «class sdbi» to false
					end if
				end tell
			end tell
			-- store the JXA call to this handler
			set JXACommandString to "Library('DC-Keynote').selectDefaultBodyItem();"
			tell script "DC-Support" to storeJXACommandString(JXACommandString)
			my speakThisWithDefaultVoice(my getLocalizedStringForKey("READY_PHRASE"))
			return true
		on error errorMessage number errorNumber
			if errorNumber is not -128 then
				my displaySpokenErrorAlert(errorMessage, "com.apple.iWork.Keynote")
			end if
			error number -128
		end try
	end tell
end selectDefaultBodyItem

on enterDefautTitleItem()
	tell application id "com.apple.iWork.Keynote"
		try
			activate
			if «class Plng» is true then
				beep
				return false
			else
				if not (exists document 1) then
					error "KEYNOTE_NO_DOCUMENT"
				end if
			end if
			tell front document
				tell «class crsl»
					if «class Ktsh» is false then
						beep
						error number -128
					else
						if «class pLck» of «class sdti» is true then
							tell script "DC-Assistive-Keynote" to playUnlockingSound()
							(*
							tell current application
								say "unlocking"
							end tell
							*)
						end if
						-- select the default body item
						-- set position of default title item to position of default title item
						set «class pLck» of «class sdti» to false
						-- press the Enter key
						tell application "System Events" to key code 76
					end if
				end tell
			end tell
			-- store the JXA call to this handler
			set JXACommandString to "Library('DC-Keynote').enterDefautTitleItem();"
			tell script "DC-Support" to storeJXACommandString(JXACommandString)
			my speakWithMutedInput(my getLocalizedStringForKey("READY_PHRASE"))
			return true
		on error errorMessage number errorNumber
			if errorNumber is not -128 then
				my displaySpokenErrorAlert(errorMessage, "com.apple.iWork.Keynote")
			end if
			error number -128
		end try
	end tell
end enterDefautTitleItem

on selectDefautTitleItem()
	tell application id "com.apple.iWork.Keynote"
		try
			activate
			if «class Plng» is true then
				beep
				return false
			else
				if not (exists document 1) then
					error "KEYNOTE_NO_DOCUMENT"
				end if
			end if
			tell front document
				tell «class crsl»
					if «class Ktsh» is false then
						beep
						error number -128
					else
						-- select the default body item
						-- set position of default title item to position of default title item
						set «class pLck» of «class sdti» to false
					end if
				end tell
			end tell
			-- store the JXA call to this handler
			set JXACommandString to "Library('DC-Keynote').selectDefautTitleItem();"
			tell script "DC-Support" to storeJXACommandString(JXACommandString)
			my speakThisWithDefaultVoice(my getLocalizedStringForKey("READY_PHRASE"))
			return true
		on error errorMessage number errorNumber
			if errorNumber is not -128 then
				my displaySpokenErrorAlert(errorMessage, "com.apple.iWork.Keynote")
			end if
			error number -128
		end try
	end tell
end selectDefautTitleItem

on pressEscapeKey()
	tell application id "com.apple.iWork.Keynote"
		try
			activate
			if «class Plng» is true then
				beep
				return false
			else
				if not (exists document 1) then
					error "KEYNOTE_NO_DOCUMENT"
				end if
			end if
			-- press the Escape key
			tell application "System Events" to key code 53
			-- store the JXA call to this handler
			set JXACommandString to "Library('DC-Keynote').pressEscapeKey();"
			tell script "DC-Support" to storeJXACommandString(JXACommandString)
			return true
		on error errorMessage number errorNumber
			if errorNumber is not -128 then
				my displaySpokenErrorAlert(errorMessage, "com.apple.iWork.Keynote")
			end if
			error number -128
		end try
	end tell
end pressEscapeKey

(* PRESENTATION SUITE *)

on startPlayingFromCurrentSlide()
	tell application id "com.apple.iWork.Keynote"
		activate
		if «class Plng» is true then
			tell the front document to «event KnststoP»
		else
			if not (exists document 1) then
				my displaySpokenErrorAlert("KEYNOTE_NO_DOCUMENT", "com.apple.iWork.Keynote")
				error number -128
			end if
		end if
		tell the front document to «event KnstplaY»
	end tell
	-- store the JXA call to this handler
	set JXACommandString to "Library('DC-Keynote').startPlayingFromCurrentSlide();"
	tell script "DC-Support" to storeJXACommandString(JXACommandString)
end startPlayingFromCurrentSlide

on startPlayingFromBeginning()
	tell application id "com.apple.iWork.Keynote"
		activate
		if «class Plng» is true then
			tell the front document to «event KnststoP»
		else
			if not (exists document 1) then
				my displaySpokenErrorAlert("KEYNOTE_NO_DOCUMENT", "com.apple.iWork.Keynote")
				error number -128
			end if
		end if
		tell front document
			try
				set targetSlide to the first «class KnSd» whose «class Kskp» is false
			on error
				my displaySpokenErrorAlert("PRESENTATION_CONTAINS_NO_UNSKIPPED_SLIDES", "com.apple.iWork.Keynote")
				error number -128
			end try
		end tell
		tell the front document to «event KntcplaF» targetSlide
	end tell
	-- store the JXA call to this handler
	set JXACommandString to "Library('DC-Keynote').startPlayingFromBeginning()"
	tell script "DC-Support" to storeJXACommandString(JXACommandString)
end startPlayingFromBeginning

on stopPlaying()
	tell application id "com.apple.iWork.Keynote"
		activate
		if «class Plng» is true then
			tell the front document to «event KnststoP»
		else
			if not (exists document 1) then
				my displaySpokenErrorAlert("KEYNOTE_NO_DOCUMENT", "com.apple.iWork.Keynote")
				error number -128
			end if
		end if
	end tell
	-- store the JXA call to this handler
	set JXACommandString to "Library('DC-Keynote').stopPlaying()"
	tell script "DC-Support" to storeJXACommandString(JXACommandString)
end stopPlaying

on goToNextAdvance()
	tell application id "com.apple.iWork.Keynote"
		activate
		if «class Plng» is true then
			«event KntcsteF»
		else
			my displaySpokenErrorAlert("NO_PLAYING_PRESENTATION", "com.apple.iWork.Keynote")
			error number -128
		end if
	end tell
	-- store the JXA call to this handler
	set JXACommandString to "Library('DC-Keynote').goToNextAdvance()"
	tell script "DC-Support" to storeJXACommandString(JXACommandString)
end goToNextAdvance

on goToPreviousSlide()
	tell application id "com.apple.iWork.Keynote"
		activate
		if «class Plng» is true then
			«event KntcsteB»
		else
			my displaySpokenErrorAlert("NO_PLAYING_PRESENTATION", "com.apple.iWork.Keynote")
			error number -128
		end if
	end tell
	-- store the JXA call to this handler
	set JXACommandString to "Library('DC-Keynote').goToPreviousSlide();"
	tell script "DC-Support" to storeJXACommandString(JXACommandString)
end goToPreviousSlide

on speakSlideNumberOfCurrentSlide()
	-- store the JXA call to this handler
	set JXACommandString to "Library('DC-Keynote').speakSlideNumberOfCurrentSlide();"
	tell script "DC-Support" to storeJXACommandString(JXACommandString)
	tell application id "com.apple.iWork.Keynote"
		activate
		if «class Plng» is true then
			set currentSlide to the «class crsl» of front document
			set currentSlideNumber to the «class KSdN» of currentSlide
			my speakThisWithDefaultVoice((my getLocalizedStringForKey("KEYNOTE_SPEAK_CURSLIDE_NUM")) & (currentSlideNumber as string))
			return true
		end if
	end tell
	return false
end speakSlideNumberOfCurrentSlide

on goToPromptedSlide()
	
	tell script "DC-Support"
		set continueButtonTitle to getLocalizedStringForKey("CONTINUE_BUTTON_TITLE")
		set displayedPrompt to getLocalizedStringForKey("SLIDE_SEARCH_DISPLAY_PROMPT")
		set spokenPrompt to getLocalizedStringForKey("SLIDE_SEARCH_SPOKEN_PROMPT")
		-- displayedPrompt, spokenPrompt, defaultAnswerString, answerIsRequired, continueButtonTitle, appID
		set userInput to promptForInput(displayedPrompt, spokenPrompt, "", true, continueButtonTitle, "com.apple.iWork.Keynote")
		set stringOrInteger to integerValueForString(userInput)
	end tell
	
end goToPromptedSlide

on goToSlideByNumber(slideNumber)
	try
		logThis("goToSlideByNumber(" & slideNumber & ")")
		tell application "Keynote Creator Studio"
			activate
			set currentVersion to version of it
			if playing is true then
				set slideCount to the count of (every slide of document 1 whose skipped is false)
				if slideNumber is greater than slideCount then
					set slideNumber to slideCount
				else if slideNumber is less than 1 then
					set slideNumber to slideCount
				end if
				show slide switcher
				delay 0.5
				tell application "System Events" to keystroke (slideNumber as text)
				delay 0.5
				accept slide switcher
			else
				if not (exists document 1) then
					error "KEYNOTE_NO_DOCUMENT"
				end if
				set slideCount to the count of (every slide of document 1 whose skipped is false)
				if slideNumber is greater than slideCount then
					set slideNumber to slideCount
				else if slideNumber is less than 1 then
					set slideNumber to slideCount
				end if
				tell front document
					set aSlide to the first slide whose slide number is slideNumber
					(* In Keynote 6.x the current slide property is read-only *)
					if currentVersion is less than "7.0.0" then
						tell aSlide
							set aShape to make new shape
							delete aShape
						end tell
					else
						set current slide to aSlide
					end if
				end tell
			end if
		end tell
		-- store the JXA call to this handler
		set JXACommandString to "Library('DC-Keynote').goToSlideByNumber(" & (slideNumber as string) & ");"
		tell script "DC-Support" to storeJXACommandString(JXACommandString)
	on error errorMessage number errorNumber
		if errorNumber is not -128 then
			my displaySpokenErrorAlert(errorMessage, "com.apple.iWork.Keynote")
		end if
		error number -128
	end try
end goToSlideByNumber

on goToSlideUsingSlideSwitcher(targetSlideNumber)
	tell application id "com.apple.iWork.Keynote"
		activate
		if «class Plng» is false then
			beep
			return false
		end if
		try
			set targetSlideNumber to targetSlideNumber as integer
		on error
			my speakThisWithDefaultVoice(targetSlideNumber as string) & " is not a number."
			error number -128
		end try
		if targetSlideNumber is 0 then
			beep
			return false
		end if
		tell front document
			if targetSlideNumber is less than 0 then
				set slideNumbers to the «class KSdN» of every «class KnSd»
				set activeSlideNumbers to {}
				repeat with i from 1 to the count of slideNumbers
					set thisSlideNumber to item i of slideNumbers
					if thisSlideNumber is not -1 then
						set the end of activeSlideNumbers to thisSlideNumber
					end if
				end repeat
				if activeSlideNumbers is {} then
					my displaySpokenErrorAlert("PRESENTATION_CONTAINS_NO_UNSKIPPED_SLIDES", "com.apple.iWork.Keynote")
					error number -128
				end if
				set targetSlideNumber to item targetSlideNumber of activeSlideNumbers
			end if
			set currentSlideSlideNumber to the «class KSdN» of the «class crsl»
		end tell
		-- stop if the current slide is the requested slide
		if currentSlideSlideNumber is targetSlideNumber then
			beep
			return true
		else if currentSlideSlideNumber < targetSlideNumber then
			set numberOfAdvances to targetSlideNumber - currentSlideSlideNumber
			«event Kntcsssl»
			repeat numberOfAdvances times
				«event Kntcmssf»
			end repeat
			«event Kntcassw»
		else if currentSlideSlideNumber > targetSlideNumber then
			set numberOfAdvances to currentSlideSlideNumber - targetSlideNumber
			«event Kntcsssl»
			repeat numberOfAdvances times
				«event Kntcmssb»
			end repeat
			«event Kntcassw»
		end if
	end tell
end goToSlideUsingSlideSwitcher

(* SAVE SUITE *)

on saveCopyOfPresentationToPublicFolder()
	saveCopyOfFrontPresentationToSpecifiedFolder((path to public folder))
end saveCopyOfPresentationToPublicFolder

on saveCopyOfFrontPresentationToSpecifiedFolder(targetFolder)
	try
		set targetFolderPath to the POSIX path of targetFolder
		set targetFolderPath to current application's class "NSString"'s stringWithString:targetFolderPath
		set targetFolderName to (targetFolderPath's lastPathComponent()) as text
		tell application id "com.apple.iWork.Keynote"
			if the (count of documents) is 0 then
				error "KEYNOTE_NO_DOCUMENT"
			end if
			set titleText to the name of the front document
			set titleText to current application's class "NSString"'s stringWithString:titleText
			set titleText to (titleText's stringByDeletingPathExtension) as string
			set POSIXPath to script "DC-Workspace"'s derivePathForDocumentInSpecifiedFolder(targetFolder, titleText, "key")
			set alertString to my getLocalizedStringForKey("SAVING_DOCUMENT_ALERT2")
			set alertString to (my replaceStringInString(alertString, "$@1", titleText)) as text
			set alertString to my replaceStringInString(alertString, "$@2", targetFolderName)
			tell current application
				say alertString
			end tell
			save front document in (POSIXPath as POSIX file)
			-- store the JXA call to this handler
			set JXACommandString to "Library('DC-Keynote').copyPresentationToRemovableDeviceAndEject();"
			tell script "DC-Support" to storeJXACommandString(JXACommandString)
		end tell
		announceCompletion()
	on error errorMessage number errorNumber
		my displaySpokenErrorAlert(errorMessage, "com.apple.iWork.Keynote")
	end try
end saveCopyOfFrontPresentationToSpecifiedFolder

on presentationSaveInDocumentsFolderUsingFirstSlideTitle()
	tell application id "com.apple.iWork.Keynote"
		try
			if the (count of documents) is 0 then
				error "KEYNOTE_NO_DOCUMENT"
			end if
			if (get file of front document) is missing value then
				set firstSlide to the first «class KnSd» of the front document whose «class Kskp» is false
				if «class Ktsh» of the firstSlide then
					set titleText to «class pDTx» of the «class sdti» of the firstSlide
					if titleText is "" then
						set titleText to (my getLocalizedStringForKey("UNTITLED"))
					end if
				else
					set titleText to (my getLocalizedStringForKey("UNTITLED"))
				end if
				set POSIXPath to script "DC-Workspace"'s derivePathForDocumentInDocumentsFolder(titleText, "key")
				save front document in (POSIXPath as POSIX file)
				set responseString to (my getLocalizedStringForKey("SAVE_IN_DOCS_COMPLETED") & titleText)
			else
				save front document
				set responseString to (my getLocalizedStringForKey("SAVE_COMPLETED"))
			end if
			delay 1
			my speakThisWithDefaultVoice(responseString)
			-- store the JXA call to this handler
			set JXACommandString to "Library('DC-Keynote').presentationSaveInDocumentsFolderUsingFirstSlideTitle();"
			tell script "DC-Support" to storeJXACommandString(JXACommandString)
		on error errorMessage number errorNumber
			if errorNumber is not -128 then
				my displaySpokenErrorAlert(errorMessage, "com.apple.iWork.Keynote")
			end if
			error number -128
		end try
	end tell
end presentationSaveInDocumentsFolderUsingFirstSlideTitle

on copyPresentationToRemovableDevice()
	tell script "DC-Workspace"
		set deviceVolumePath to getPathForSingleRemovableMediaDevice()
	end tell
	log deviceVolumePath
	tell application id "com.apple.iWork.Keynote"
		try
			if the (count of documents) is 0 then
				error "KEYNOTE_NO_DOCUMENT"
			end if
			set titleText to the name of the front document
			set titleText to current application's class "NSString"'s stringWithString:titleText
			set titleText to (titleText's stringByDeletingPathExtension) as string
			set POSIXPath to script "DC-Workspace"'s derivePathForDocumentInSpecifiedFolder(deviceVolumePath, titleText, "key")
			set aString to current application's NSString's stringWithString:deviceVolumePath
			set volumeName to item 3 of (aString's componentsSeparatedByString:"/") as list
			set alertString to my getLocalizedStringForKey("SAVING_DOCUMENT_ALERT")
			set alertString to my replaceStringInString(alertString, "$@1", titleText)
			set alertString to my replaceStringInString(alertString, "$@2", volumeName)
			tell current application
				say alertString without waiting until completion
			end tell
			save front document in (POSIXPath as POSIX file)
			my announceCompletion()
			-- store the JXA call to this handler
			set JXACommandString to "Library('DC-Keynote').copyPresentationToRemovableDevice();"
			tell script "DC-Support" to storeJXACommandString(JXACommandString)
			return POSIXPath
		on error errorMessage number errorNumber
			if errorNumber is not -128 then
				my displaySpokenErrorAlert(errorMessage, "com.apple.iWork.Keynote")
			end if
			error number -128
		end try
	end tell
end copyPresentationToRemovableDevice

on copyPresentationToRemovableDeviceAndEject()
	tell script "DC-Workspace"
		set deviceVolumePath to getPathForSingleRemovableMediaDevice()
	end tell
	tell application id "com.apple.iWork.Keynote"
		try
			if the (count of documents) is 0 then
				error "KEYNOTE_NO_DOCUMENT"
			end if
			set titleText to the name of the front document
			set titleText to current application's class "NSString"'s stringWithString:titleText
			set titleText to (titleText's stringByDeletingPathExtension) as string
			set POSIXPath to script "DC-Workspace"'s derivePathForDocumentInSpecifiedFolder(deviceVolumePath, titleText, "key")
			set aString to current application's NSString's stringWithString:deviceVolumePath
			set volumeName to (item 3 of (aString's componentsSeparatedByString:"/") as list) as text
			set alertString to my getLocalizedStringForKey("SAVING_DOCUMENT_ALERT")
			set alertString to (my replaceStringInString(alertString, "$@1", titleText)) as text
			set alertString to my replaceStringInString(alertString, "$@2", volumeName)
			tell current application
				say alertString
			end tell
			save front document in (POSIXPath as POSIX file)
			tell script "DC-Workspace"
				unmountRemovableMediaDeviceAtVolumePath(deviceVolumePath, true)
			end tell
			-- store the JXA call to this handler
			set JXACommandString to "Library('DC-Keynote').copyPresentationToRemovableDeviceAndEject();"
			tell script "DC-Support" to storeJXACommandString(JXACommandString)
		on error errorMessage number errorNumber
			if errorNumber is not -128 then
				my displaySpokenErrorAlert(errorMessage, "com.apple.iWork.Keynote")
			end if
			error number -128
		end try
	end tell
end copyPresentationToRemovableDeviceAndEject

(* EXPORT *)

on captureCurrentSlideToPublicFolder()
	try
		tell application id "com.apple.iWork.Keynote"
			activate
			if «class Plng» is false then
				error "PRESENTATION_NOT_PLAYING"
			end if
			tell front document
				set currentDocName to the name of it
				tell script "DC-Workspace"
					set currentDocName to removeFileExtension(currentDocName)
				end tell
				set currentSlideNumber to the «class KSdN» of the «class crsl»
			end tell
		end tell
		set localizedWordForSlide to getLocalizedStringForKey("WORD_FOR_SLIDE")
		set captureFileName to (currentDocName & "-" & localizedWordForSlide & "-" & currentSlideNumber)
		tell script "DC-Workspace"
			set captureFilePath to derivePathForDocumentInSpecifiedFolder((path to public folder), captureFileName, "png")
		end tell
		do shell script "screencapture" & space & quoted form of captureFilePath
		-- store the JXA call to this handler
		set JXACommandString to "Library('DC-Keynote').captureCurrentSlideToPublicFolder();"
		tell script "DC-Support" to storeJXACommandString(JXACommandString)
		announceCompletion()
	on error errorMessage number errorNumber
		my displaySpokenErrorAlert(errorMessage, "com.apple.iWork.Keynote")
	end try
end captureCurrentSlideToPublicFolder

on exportFrontDocumentToPDFWithReveal()
	tell application id "com.apple.iWork.Keynote" to activate
	set exportedPDFFile to exportFrontDocumentToPDF()
	tell script "DC-Workspace" to revealInFinder({exportedPDFFile})
	return true
end exportFrontDocumentToPDFWithReveal

on exportFrontDocumentToMovieWithReveal()
	tell application id "com.apple.iWork.Keynote" to activate
	set exportedPDFFile to exportFrontDocumentToMovie()
	tell script "DC-Workspace" to revealInFinder({exportedPDFFile})
	return true
end exportFrontDocumentToMovieWithReveal

on exportFrontDocumentToPDF()
	(* EXPORT THE PRESENTATION TO PDF *)
	
	say (getLocalizedStringForKey("BEGINNING_PDF_EXPORT_SPOKEN_MSG"))
	
	set usePDFEncryption to true
	
	set cancelButtonTitle to getLocalizedStringForKey("CANCEL_BUTTON_TITLE")
	set noPasswordButtonTitle to getLocalizedStringForKey("NO_PASSWORD_BUTTON_TITLE")
	set okButtonTitle to getLocalizedStringForKey("OK_BUTTON_TITLE")
	set exportPasswordSpokenPrompt to getLocalizedStringForKey("PDF_PASSWORD_SPOKEN_PROMPT")
	set exportPasswordDialogPrompt to getLocalizedStringForKey("PDF_PASSWORD_DIALOG_PROMPT")
	set tryAgainButtonTitle to getLocalizedStringForKey("TRY_AGAIN_BUTTON_TITLE")
	set enterPasswordAgainPrompt to getLocalizedStringForKey("PDF_ENTER_PASSWORD_AGAIN_PROMPT")
	set passwordMismatchMessage to getLocalizedStringForKey("PDF_PASSWORD_MISMATCH_MSG")
	
	try
		tell application id "com.apple.iWork.Keynote"
			activate
			if «class Plng» is true then
				tell the front document to «event KnststoP»
			end if
			if not (exists document 1) then
				error "KEYNOTE_NO_DOCUMENT"
			end if
			
			if usePDFEncryption is true then
				-- PROMPT FOR PASSWORD (OPTIONAL)
				set sayUtilityPath to "/usr/bin/say"
				set theTask to (current application's NSTask's launchedTaskWithLaunchPath:sayUtilityPath arguments:{exportPasswordSpokenPrompt})
				repeat
					try
						display dialog exportPasswordDialogPrompt default answer ¬
							"" buttons {cancelButtonTitle, noPasswordButtonTitle, okButtonTitle} ¬
							default button 3 with hidden answer
						copy the result to ¬
							{button returned:buttonPressed, text returned:firstPassword}
					on error
						-- stop speaking
						try
							theTask's terminate()
						end try
						error number -128
					end try
					if buttonPressed is noPasswordButtonTitle then
						set usePDFEncryption to false
						exit repeat
					else
						display dialog enterPasswordAgainPrompt default answer ¬
							"" buttons {cancelButtonTitle, noPasswordButtonTitle, okButtonTitle} ¬
							default button 3 with hidden answer
						copy the result to ¬
							{button returned:buttonPressed, text returned:secondPassword}
						if buttonPressed is noPasswordButtonTitle then
							set usePDFEncryption to false
							exit repeat
						else
							if firstPassword is not secondPassword then
								display dialog passwordMismatchMessage buttons ¬
									{cancelButtonTitle, tryAgainButtonTitle} default button 2
							else
								set providedPassword to the firstPassword
								set usePDFEncryption to true
								exit repeat
							end if
						end if
					end if
				end repeat
			end if
			
			-- DERIVE NAME AND FILE PATH FOR NEW EXPORT FILE
			set documentName to the name of the front document
			if documentName ends with ".key" then ¬
				set documentName to text 1 thru -5 of documentName
			
			tell script "DC-Workspace"
				set targetFilePOSIXPath to derivePathForDocumentInDocumentsFolder(documentName, "pdf")
			end tell
			set targetFileHFSPath to targetFilePOSIXPath as POSIX file as string
			
			-- EXPORT THE DOCUMENT
			with timeout of 1200 seconds
				if usePDFEncryption is true then
					«event Knstexpo» front document given «class kfil»:file targetFileHFSPath ¬
						, «class exft»:«constant KnefKpdf», «class expr»:{«class KxPW»:providedPassword}
				else
					«event Knstexpo» front document given «class kfil»:file targetFileHFSPath, «class exft»:«constant KnefKpdf»
				end if
			end timeout
			
			return (targetFileHFSPath as alias)
		end tell
	on error errorMessage number errorNumber
		if errorNumber is not -128 then
			my displaySpokenErrorAlert(errorMessage, "com.apple.iWork.Keynote")
		end if
		error number -128
	end try
end exportFrontDocumentToPDF

on exportFrontDocumentToMovie()
	try
		tell application id "com.apple.iWork.Keynote"
			activate
			if «class Plng» is true then
				tell the front document to «event KnststoP»
			end if
			if not (exists document 1) then
				error "KEYNOTE_NO_DOCUMENT"
			end if
			
			-- DERIVE NAME AND FILE PATH FOR NEW EXPORT FILE
			set documentName to the name of the front document
			if documentName ends with ".key" then ¬
				set documentName to text 1 thru -5 of documentName
			
			tell script "DC-Workspace"
				set targetFilePOSIXPath to derivePathForDocumentInMoviesFolder(documentName, "m4v")
			end tell
			set targetFileHFSPath to targetFilePOSIXPath as POSIX file as string
			
			-- EXPORT THE DOCUMENT
			with timeout of 1200 seconds
				«event Knstexpo» front document given «class kfil»:file targetFileHFSPath ¬
					, «class exft»:«constant KnefKmov», «class expr»:{«class Kxmf»:«constant KnmfKmf7»}
			end timeout
			
			return (targetFileHFSPath as alias)
			
		end tell
	on error errorMessage number errorNumber
		if errorNumber is not -128 then
			my displaySpokenErrorAlert(errorMessage, "com.apple.iWork.Keynote")
		end if
		error number -128
	end try
end exportFrontDocumentToMovie

(* SIZING OBJECTS *)

on reduceSizeOfSelectedUnlockedSlideItemsByPercentage(percentageString)
	tell application id "com.apple.iWork.Keynote"
		try
			set targetPercentage to my integerValueForString(percentageString)
			if targetPercentage is greater than 99 then
				my displaySpokenErrorAlert("INVALID_SIZING_DIMENSION", "com.apple.iWork.Keynote")
				error number -128
			end if
			if «class Plng» is true then
				tell the front document to «event KnststoP»
			else
				if not (exists document 1) then
					my displaySpokenErrorAlert("KEYNOTE_NO_DOCUMENT", "com.apple.iWork.Keynote")
					error number -128
				end if
			end if
			set theseSlideItems to my getSelectedSlideItems()
			if theseSlideItems is {} then
				my displaySpokenErrorAlert("NO_SELECTED_SLIDE_ITEMS", "com.apple.iWork.Keynote")
				error number -128
			end if
			set sizeFromDirection to 1 -- (0 = anchor top & left, 1 = anchor center)
			set sizeFromDirection to 1 -- (0 = anchor top & left, 1 = anchor center)
			-- change to include separate amounts for height and width determined by percentage of current values
			repeat with i from 1 to the count of theseSlideItems
				set thisSlideItem to item i of theseSlideItems
				set currentWidth to «class sitw» of thisSlideItem
				set currentHeight to «class sith» of thisSlideItem
				set percentageFactor to 1 - (targetPercentage / 100) -- (targetPercentage / 100) + 1
				set newWidth to currentWidth * percentageFactor
				set newHeight to currentHeight * percentageFactor
				###########
				if sizeFromDirection is 0 then -- size width, keeping left position
					set «class sitw» of thisSlideItem to newWidth
					set «class sith» of thisSlideItem to newHeight
				else if sizeFromDirection is 1 then -- size width, keeping right position
					copy «class sipo» of thisSlideItem to {leftOffset, topOffset}
					copy {«class sitw» of thisSlideItem, «class sith» of thisSlideItem} to {itemWidth, itemHeight}
					set rightOffset to leftOffset + itemWidth
					set bottomOffset to topOffset + itemHeight
					set «class sitw» of thisSlideItem to newWidth
					set «class sith» of thisSlideItem to newHeight
					set «class sipo» of thisSlideItem to {leftOffset - ((newWidth - itemWidth) div 2), topOffset - ((newHeight - itemHeight) div 2)}
				end if
			end repeat
		on error errorMessage number errorNumber
			if errorNumber is not -128 then
				my displaySpokenErrorAlert(errorMessage, "com.apple.iWork.Keynote")
			end if
			error number -128
		end try
	end tell
end reduceSizeOfSelectedUnlockedSlideItemsByPercentage

on increaseSizeOfSelectedUnlockedSlideItemsByPercentage(percentageString)
	tell application id "com.apple.iWork.Keynote"
		try
			if «class Plng» is true then
				tell the front document to «event KnststoP»
			else
				if not (exists document 1) then
					my displaySpokenErrorAlert("KEYNOTE_NO_DOCUMENT", "com.apple.iWork.Keynote")
					error number -128
				end if
			end if
			
			set targetPercentage to my integerValueForString(percentageString)
			if targetPercentage is less than 1 then
				my displaySpokenErrorAlert("INVALID_SIZING_DIMENSION", "com.apple.iWork.Keynote")
				error number -128
			end if
			
			set theseSlideItems to my getSelectedSlideItems()
			if theseSlideItems is {} then
				my displaySpokenErrorAlert("NO_SELECTED_SLIDE_ITEMS", "com.apple.iWork.Keynote")
				error number -128
			end if
			set sizeFromDirection to 1 -- (0 = anchor top & left, 1 = anchor center)
			-- change to include separate amounts for height and width determined by percentage of current values
			repeat with i from 1 to the count of theseSlideItems
				set thisSlideItem to item i of theseSlideItems
				set currentWidth to «class sitw» of thisSlideItem
				set currentHeight to «class sith» of thisSlideItem
				set percentageFactor to (targetPercentage / 100) + 1
				set newWidth to currentWidth * percentageFactor
				set newHeight to currentHeight * percentageFactor
				###########
				if sizeFromDirection is 0 then -- size width, keeping left position
					set «class sitw» of thisSlideItem to newWidth
					set «class sith» of thisSlideItem to newHeight
				else if sizeFromDirection is 1 then -- size width, keeping right position
					copy «class sipo» of thisSlideItem to {leftOffset, topOffset}
					copy {«class sitw» of thisSlideItem, «class sith» of thisSlideItem} to {itemWidth, itemHeight}
					set rightOffset to leftOffset + itemWidth
					set bottomOffset to topOffset + itemHeight
					set «class sitw» of thisSlideItem to newWidth
					set «class sith» of thisSlideItem to newHeight
					set «class sipo» of thisSlideItem to {leftOffset - ((newWidth - itemWidth) div 2), topOffset - ((newHeight - itemHeight) div 2)}
				end if
			end repeat
		on error errorMessage number errorNumber
			if errorNumber is not -128 then
				my displaySpokenErrorAlert(errorMessage, "com.apple.iWork.Keynote")
			end if
			error number -128
		end try
	end tell
end increaseSizeOfSelectedUnlockedSlideItemsByPercentage

on setSizeOfSelectedUnlockedSlideItems(dimensionString)
	tell application id "com.apple.iWork.Keynote"
		try
			set targetDimension to my integerValueForString(dimensionString)
			if targetDimension is less than 1 then
				my displaySpokenErrorAlert("INVALID_SIZING_DIMENSION", "com.apple.iWork.Keynote")
				error number -128
			end if
			if «class Plng» is true then
				tell the front document to «event KnststoP»
			else
				if not (exists document 1) then
					my displaySpokenErrorAlert("KEYNOTE_NO_DOCUMENT", "com.apple.iWork.Keynote")
					error number -128
				end if
			end if
			set theseSlideItems to my getSelectedSlideItems()
			if theseSlideItems is {} then
				my displaySpokenErrorAlert("NO_SELECTED_SLIDE_ITEMS", "com.apple.iWork.Keynote")
				error number -128
			end if
			set sizeFromDirection to 1 -- (0 = anchor top & left, 1 = anchor center)
			repeat with i from 1 to the count of theseSlideItems
				set thisSlideItem to item i of theseSlideItems
				if sizeFromDirection is 0 then -- size width, keeping left position
					set «class sitw» of thisSlideItem to targetDimension
					set «class sith» of thisSlideItem to targetDimension
				else if sizeFromDirection is 1 then -- size width, keeping right position
					copy «class sipo» of thisSlideItem to {leftOffset, topOffset}
					copy {«class sitw» of thisSlideItem, «class sith» of thisSlideItem} to {itemWidth, itemHeight}
					set rightOffset to leftOffset + itemWidth
					set bottomOffset to topOffset + itemHeight
					set «class sitw» of thisSlideItem to targetDimension
					set «class sith» of thisSlideItem to targetDimension
					set «class sipo» of thisSlideItem to {leftOffset - ((targetDimension - itemWidth) div 2), topOffset - ((targetDimension - itemHeight) div 2)}
				end if
			end repeat
		on error errorMessage number errorNumber
			if errorNumber is not -128 then
				my displaySpokenErrorAlert(errorMessage, "com.apple.iWork.Keynote")
			end if
			error number -128
		end try
	end tell
end setSizeOfSelectedUnlockedSlideItems

on matchSizeOfSelectedSlideItemsToSmallestSelectedItem()
	tell application id "com.apple.iWork.Keynote"
		set theseSlideItems to my getSelectedSlideItems()
		if theseSlideItems is {} then
			my displaySpokenErrorAlert("NO_SELECTED_SLIDE_ITEMS", "com.apple.iWork.Keynote")
			error number -128
		end if
		set targetDimension to 100000
		repeat with i from 1 to the count of theseSlideItems
			set thisSlideItem to item i of theseSlideItems
			set thisWidth to «class sitw» of thisSlideItem
			set thisHeight to «class sith» of thisSlideItem
			if thisWidth is less than targetDimension then
				set targetDimension to thisHeight
			end if
			if thisHeight is less than targetDimension then
				set targetDimension to thisHeight
			end if
		end repeat
		set sizeFromDirection to 1 -- (0 = anchor top & left, 1 = anchor center)
		repeat with i from 1 to the count of theseSlideItems
			set thisSlideItem to item i of theseSlideItems
			if sizeFromDirection is 0 then -- size width, keeping left position
				set «class sitw» of thisSlideItem to targetDimension
				set «class sith» of thisSlideItem to targetDimension
			else if sizeFromDirection is 1 then -- size width, keeping right position
				copy «class sipo» of thisSlideItem to {leftOffset, topOffset}
				copy {«class sitw» of thisSlideItem, «class sith» of thisSlideItem} to {itemWidth, itemHeight}
				set rightOffset to leftOffset + itemWidth
				set bottomOffset to topOffset + itemHeight
				set «class sitw» of thisSlideItem to targetDimension
				set «class sith» of thisSlideItem to targetDimension
				set «class sipo» of thisSlideItem to {leftOffset - ((targetDimension - itemWidth) div 2), topOffset - ((targetDimension - itemHeight) div 2)}
			end if
		end repeat
	end tell
end matchSizeOfSelectedSlideItemsToSmallestSelectedItem

on matchSizeOfSelectedSlideItemsToLargestSelectedItem()
	tell application id "com.apple.iWork.Keynote"
		set theseSlideItems to my getSelectedSlideItems()
		if theseSlideItems is {} then
			my displaySpokenErrorAlert("NO_SELECTED_SLIDE_ITEMS", "com.apple.iWork.Keynote")
			error number -128
		end if
		set targetDimension to 0
		repeat with i from 1 to the count of theseSlideItems
			set thisSlideItem to item i of theseSlideItems
			set thisWidth to «class sitw» of thisSlideItem
			set thisHeight to «class sith» of thisSlideItem
			if thisWidth is greater than targetDimension then
				set targetDimension to thisHeight
			end if
			if thisHeight is greater than targetDimension then
				set targetDimension to thisHeight
			end if
		end repeat
		set sizeFromDirection to 1 -- (0 = anchor top & left, 1 = anchor center)
		repeat with i from 1 to the count of theseSlideItems
			set thisSlideItem to item i of theseSlideItems
			if sizeFromDirection is 0 then -- size width, keeping left position
				set «class sitw» of thisSlideItem to targetDimension
				set «class sith» of thisSlideItem to targetDimension
			else if sizeFromDirection is 1 then -- size width, keeping right position
				copy «class sipo» of thisSlideItem to {leftOffset, topOffset}
				copy {«class sitw» of thisSlideItem, «class sith» of thisSlideItem} to {itemWidth, itemHeight}
				set rightOffset to leftOffset + itemWidth
				set bottomOffset to topOffset + itemHeight
				set «class sitw» of thisSlideItem to targetDimension
				set «class sith» of thisSlideItem to targetDimension
				set «class sipo» of thisSlideItem to {leftOffset - ((targetDimension - itemWidth) div 2), topOffset - ((targetDimension - itemHeight) div 2)}
			end if
		end repeat
	end tell
end matchSizeOfSelectedSlideItemsToLargestSelectedItem

on setHeightOfSelectedUnlockedSlideItems(dimensionString)
	tell application id "com.apple.iWork.Keynote"
		try
			set targetDimension to my integerValueForString(dimensionString)
			if targetDimension is less than 1 then
				my displaySpokenErrorAlert("INVALID_SIZING_DIMENSION", "com.apple.iWork.Keynote")
				error number -128
			end if
			if «class Plng» is true then
				tell the front document to «event KnststoP»
			else
				if not (exists document 1) then
					my displaySpokenErrorAlert("KEYNOTE_NO_DOCUMENT", "com.apple.iWork.Keynote")
					error number -128
				end if
			end if
			set theseSlideItems to my getSelectedSlideItems()
			if theseSlideItems is {} then
				my displaySpokenErrorAlert("NO_SELECTED_SLIDE_ITEMS", "com.apple.iWork.Keynote")
				error number -128
			end if
			set sizeFromDirection to 1 -- (0 = anchor top, 1 = anchor bottom)
			repeat with i from 1 to the count of theseSlideItems
				set thisSlideItem to item i of theseSlideItems
				if sizeFromDirection is 0 then -- size height, keeping top position
					set «class sith» of thisSlideItem to targetDimension
				else if sizeFromDirection is 1 then -- size height, keeping bottom position
					copy «class sipo» of thisSlideItem to {leftOffset, topOffset}
					copy {«class sitw» of thisSlideItem, «class sith» of thisSlideItem} to {itemWidth, itemHeight}
					set rightOffset to leftOffset + itemWidth
					set bottomOffset to topOffset + itemHeight
					set «class sith» of thisSlideItem to targetDimension
					set «class sipo» of thisSlideItem to {leftOffset, (topOffset - (targetDimension - itemHeight))}
				end if
			end repeat
		on error errorMessage number errorNumber
			if errorNumber is not -128 then
				my displaySpokenErrorAlert(errorMessage, "com.apple.iWork.Keynote")
			end if
			error number -128
		end try
	end tell
end setHeightOfSelectedUnlockedSlideItems

on setWidthOfSelectedUnlockedSlideItems(dimensionString)
	tell application id "com.apple.iWork.Keynote"
		try
			set targetDimension to my integerValueForString(dimensionString)
			if targetDimension is less than 1 then
				my displaySpokenErrorAlert("INVALID_SIZING_DIMENSION", "com.apple.iWork.Keynote")
				error number -128
			end if
			if «class Plng» is true then
				tell the front document to «event KnststoP»
			else
				if not (exists document 1) then
					my displaySpokenErrorAlert("KEYNOTE_NO_DOCUMENT", "com.apple.iWork.Keynote")
					error number -128
				end if
			end if
			set theseSlideItems to my getSelectedSlideItems()
			if theseSlideItems is {} then
				my displaySpokenErrorAlert("NO_SELECTED_SLIDE_ITEMS", "com.apple.iWork.Keynote")
				error number -128
			end if
			set sizeFromDirection to 0 -- (0 = anchor left, 1 = anchor right)
			repeat with i from 1 to the count of theseSlideItems
				set thisSlideItem to item i of theseSlideItems
				if sizeFromDirection is 0 then -- size width, keeping left position
					set «class sitw» of thisSlideItem to targetDimension
				else if sizeFromDirection is 1 then -- size width, keeping right position
					copy «class sipo» of thisSlideItem to {leftOffset, topOffset}
					copy {«class sitw» of thisSlideItem, «class sith» of thisSlideItem} to {itemWidth, itemHeight}
					set rightOffset to leftOffset + itemWidth
					set bottomOffset to topOffset + itemHeight
					set «class sitw» of thisSlideItem to targetDimension
					set «class sipo» of thisSlideItem to {(leftOffset - (targetDimension - itemWidth)), topOffset}
				end if
			end repeat
		on error errorMessage number errorNumber
			if errorNumber is not -128 then
				my displaySpokenErrorAlert(errorMessage, "com.apple.iWork.Keynote")
			end if
			error number -128
		end try
	end tell
end setWidthOfSelectedUnlockedSlideItems

on addHeightLabelsForSelectedShapes()
	tell application id "com.apple.iWork.Keynote"
		try
			activate
			set theseItems to my getSelectedSlideItems()
			set theseShapes to {}
			repeat with i from 1 to the count of theseItems
				set thisItem to item i of theseItems
				if the class of thisItem is «class sshp» then
					set the end of theseShapes to thisItem
				end if
			end repeat
			if theseShapes is {} then error "NO_SELECTED_SHAPES"
			
			tell «class crsl» of front document
				repeat with i from 1 to the count of theseShapes
					set thisShape to item i of theseShapes
					copy «class sipo» of thisShape to {hOffset, vOffset}
					set shapeHeight to the «class sith» of thisShape
					set shapeWidth to the «class sitw» of thisShape
					set thisTextItem to make new «class shtx» with properties {«class pDTx»:shapeHeight}
					tell «class pDTx» of thisTextItem
						set font to "Helvetica Neue Medium"
						set size to 24
					end tell
					set «class sitw» of thisTextItem to shapeWidth
					set textItemHeight to «class sith» of thisTextItem
					set «class sipo» of thisTextItem to {hOffset, vOffset - textItemHeight}
				end repeat
			end tell
		on error errorMessage number errorNumber
			if errorNumber is not -128 then
				my displaySpokenErrorAlert(errorMessage, "com.apple.iWork.Keynote")
			end if
			error number -128
		end try
	end tell
end addHeightLabelsForSelectedShapes

on integerValueForString(thisString)
	if the class of thisString is integer then return thisString
	set stringsForOne to my getItemsFromDelimitedString(my getLocalizedStringForKey("STRINGS_FOR_ONE"), ",") -- {"won", "one"}
	set stringsForTwo to my getItemsFromDelimitedString(my getLocalizedStringForKey("STRINGS_FOR_TWO"), ",") -- {"to", "too", "two"}
	set stringsForThree to my getItemsFromDelimitedString(my getLocalizedStringForKey("STRINGS_FOR_THREE"), ",") -- {"three"}
	set stringsForFour to my getItemsFromDelimitedString(my getLocalizedStringForKey("STRINGS_FOR_FOUR"), ",") -- {"four"}
	set stringsForFive to my getItemsFromDelimitedString(my getLocalizedStringForKey("STRINGS_FOR_FIVE"), ",") -- {"five"}
	set stringsForSix to my getItemsFromDelimitedString(my getLocalizedStringForKey("STRINGS_FOR_SIX"), ",") -- {"six"}
	set stringsForSeven to my getItemsFromDelimitedString(my getLocalizedStringForKey("STRINGS_FOR_SEVEN"), ",") -- {"seven"}
	set stringsForEight to my getItemsFromDelimitedString(my getLocalizedStringForKey("STRINGS_FOR_EIGHT"), ",") -- {"eight"}
	set stringsForNine to my getItemsFromDelimitedString(my getLocalizedStringForKey("STRINGS_FOR_NINE"), ",") -- {"nine"}
	set stringsForTen to my getItemsFromDelimitedString(my getLocalizedStringForKey("STRINGS_FOR_TEN"), ",") -- {"ten"}
	
	if thisString is in stringsForOne then
		return 1
	else if thisString is in stringsForTwo then
		return 2
	else if thisString is in stringsForThree then
		return 3
	else if thisString is in stringsForFour then
		return 4
	else if thisString is in stringsForFive then
		return 5
	else if thisString is in stringsForSix then
		return 6
	else if thisString is in stringsForSeven then
		return 7
	else if thisString is in stringsForEight then
		return 8
	else if thisString is in stringsForNine then
		return 9
	else if thisString is in stringsForTen then
		return 10
	end if
	
	try
		return thisString as integer
	on error errorMessage
		log errorMessage
		set thisErrorMessage to (localized string "VALUE_NOT_NUMBER" in bundle thisBundlePath) & thisString
		my displaySpokenErrorAlert(thisErrorMessage, "com.apple.iWork.Keynote")
		error number -128
	end try
end integerValueForString

on getItemsFromDelimitedString(thisString, thisDelimiter)
	set thisString to current application's NSString's stringWithString:thisString
	set theseStrings to thisString's componentsSeparatedByString:thisDelimiter
	theseStrings as list
end getItemsFromDelimitedString


(* WORKING WITH IMAGES *)

on showImageStackForCurrentSlide()
	tell application "Keynote Creator Studio"
		activate
		if playing is true then
			beep
			error number -128
		else
			if not (exists document 1) then
				error "KEYNOTE_NO_DOCUMENT"
			end if
		end if
		try
			tell front document
				tell current slide
					set imageCount to the count of images
					if imageCount is 0 then
						error "SLIDE_NO_IMAGES"
					end if
					tell current application
						do shell script "sleep 0.5"
					end tell
					repeat with i from 1 to the imageCount
						tell image i
							set imageWidth to its width
							set imageHeight to its height
							set imagePosition to its position
						end tell
						set the shapeOverlay to make new shape with properties {height:imageHeight, width:imageWidth, position:imagePosition, opacity:50, object text:(i as string)}
						set size of object text of the shapeOverlay to 64.0
						tell current application
							say ((i as string))
						end tell
						tell current application
							do shell script "sleep 0.5"
						end tell
						delete shapeOverlay
					end repeat
				end tell
			end tell
			-- store the JXA call to this handler
			set JXACommandString to "Library('DC-Keynote').showImageStackForCurrentSlide();"
			tell script "DC-Support" to storeJXACommandString(JXACommandString)
		on error errorMessage number errorNumber
			if errorNumber is not -128 then
				my displaySpokenErrorAlert(errorMessage, "com.apple.iWork.Keynote")
			end if
			error number -128
		end try
	end tell
end showImageStackForCurrentSlide

on speakDescriptionOfLargestImageOnCurrentSlide()
	try
		tell application id "com.apple.iWork.Keynote"
			set playingStatus to «class Plng» of it
			if not (exists document 1) then
				my displaySpokenErrorAlert("KEYNOTE_NO_DOCUMENT", "com.apple.iWork.Keynote")
				error number -128
			end if
			tell front document
				tell (get «class crsl»)
					set imageCount to the count of every «class imag» of it
					if imageCount is 0 then error "IMAGES_HAVE_NO_DESCRIPTION"
					set largestVolume to 0
					repeat with i from 1 to imageCount
						set thisImage to «class imag» i
						set thisWidth to «class sitw» of thisImage
						set thisHeight to «class sith» of thisImage
						set thisVolume to thisWidth * thisHeight
						if thisVolume is greater than largestVolume then
							set largestVolume to thisVolume
							set targetImage to thisImage
						end if
					end repeat
					set imageDescription to «class dscr» of targetImage
					if imageDescription is missing value or imageDescription is "" then
						error "IMAGE_HAS_NO_DESCRIPTION"
					else
						my speakWithMutedInput(imageDescription)
					end if
				end tell
			end tell
		end tell
	on error errorMessage number errorNumber
		if errorNumber is not -128 then
			if playingStatus is false then
				my displaySpokenErrorAlert(errorMessage, "com.apple.iWork.Keynote")
			else
				set errorString to my getLocalizedStringForKey(errorMessage)
				my speakWithMutedInput(errorString)
			end if
		end if
		error number -128
	end try
end speakDescriptionOfLargestImageOnCurrentSlide

(* DESCRIPTIONS OVER IMAGES *)

on overlayImageAllDescriptions(metadataIndicator, scopeIndicator, fontSizingIndicator)
	-- metadataIndicator 0=description, 1=title, 2=filename
	set overlayPadding to 18
	set textOverlayTypeface to "Helvetica"
	set textFontSizeFixed to 28
	set textOverlayFontSizeLarge to 36
	set textOverlayFontSizeMedium to 24
	set textOverlayFontSizeSmall to 18
	set textOverlayRGBColorValues to {65535, 65535, 65535}
	
	if scopeIndicator as string is "0" then
		set targetScope to "All Slides"
	else
		"Current Slide"
	end if
	if fontSizingIndicator as string is "0" then
		set fontSizeMethod to "Adjustable"
	else
		set fontSizeMethod to "Fixed"
	end if
	
	tell application id "com.apple.iWork.Keynote"
		activate
		if «class Plng» is true then
			tell the front document to «event KnststoP»
		else
			if not (exists document 1) then
				my displaySpokenErrorAlert("KEYNOTE_NO_DOCUMENT", "com.apple.iWork.Keynote")
				error number -128
			end if
		end if
		tell front document
			set documentWidth to its «class sitw»
			set documentHeight to its «class sith»
			if scopeIndicator as string is "0" then
				set theseSlides to every «class KnSd» whose «class Kskp» is false
			else
				set theseSlides to {}
				set the end of theseSlides to the «class crsl»
			end if
			repeat with i from 1 to the count of theseSlides
				set thisSlide to item i of theseSlides
				set imageCount to the count of every «class imag» of thisSlide
				repeat with q from 1 to the imageCount
					set thisImage to «class imag» q of thisSlide
					if metadataIndicator is 0 then
						-- description
						set thisString to the «class dscr» of thisImage
					else if metadataIndicator is 1 then
						-- title
						-- since there is no access to image metadata from within Keynote, use the filename and attempt to find the image in Photos and use its metadata 
						set thisString to the «class atfn» of thisImage
						set thisString to my removeFileExtension(thisString)
						-- check to see if image is in current Photos library
						set thisMediaItemID to my retrievePhotosIDForKeynoteImage(thisImage)
						if thisMediaItemID is not false then
							-- get the name (title) of the Photos image
							set thisTitle to my nameForMediaItemByID(thisMediaItemID)
							if thisTitle is not "" then
								-- if there is a name, then use it
								set thisString to thisTitle
							end if
						end if
					else
						-- filename
						set thisString to the «class atfn» of thisImage
					end if
					if thisString is not "" then
						copy (my deriveBoundsOfVisibleImageMaskFor(thisImage)) to {x, y, x1, y1}
						tell thisSlide
							set thisTextItem to make new «class shtx» with properties {«class sipo»:{x, y}, «class sitw»:(x1 - x), «class pDTx»:thisString}
						end tell
						tell thisTextItem
							tell «class pDTx»
								set font to textOverlayTypeface
								if fontSizeMethod is "Adjustable" then
									set fontSizeFactor to (x1 - x) div (length of thisString)
									log "fontSizeFactor: " & fontSizeFactor
									if fontSizeFactor is less than 20 then
										set textOverlayFontSize to textOverlayFontSizeSmall
									else if fontSizeFactor is less than 25 then
										set textOverlayFontSize to textOverlayFontSizeMedium
									else
										set textOverlayFontSize to textOverlayFontSizeLarge
									end if
								else
									set textOverlayFontSize to textFontSizeFixed
								end if
								set size to textOverlayFontSize
								set color of it to textOverlayRGBColorValues
							end tell
							-- position the text overlay at bottom of host image
							set textItemHeight to its «class sith»
							copy its «class sipo» to {tx, ty}
							set its «class sipo» to {tx, (y1 - textItemHeight - overlayPadding)}
						end tell
					end if
				end repeat
			end repeat
		end tell
	end tell
end overlayImageAllDescriptions

on deriveBoundsOfVisibleImageMaskFor(thisImage)
	tell application id "com.apple.iWork.Keynote"
		tell front document
			set documentWidth to its «class sitw»
			set documentHeight to its «class sith»
			
			copy «class sipo» of thisImage to {imageMaskTopLeftHorizontalOffset, imageMaskTopLeftVerticalOffset}
			set imageMaskWidth to «class sitw» of thisImage
			set imageMaskHeight to «class sith» of thisImage
			
			-- derive the top left horizontal offset of the visible image mask
			if imageMaskTopLeftHorizontalOffset is less than 0 then
				set visbleImageMaskTopLeftHorizontalOffset to 0
			else
				set visbleImageMaskTopLeftHorizontalOffset to imageMaskTopLeftHorizontalOffset
			end if
			
			-- derive the bottom right horizontal offset of the visible image mask
			set imageMaskBottomRightHorizontalOffset to imageMaskTopLeftHorizontalOffset + imageMaskWidth
			if imageMaskBottomRightHorizontalOffset is greater than documentWidth then
				set visbleImageMaskBottomRightHorizontalOffset to documentWidth
			else
				set visbleImageMaskBottomRightHorizontalOffset to imageMaskBottomRightHorizontalOffset
			end if
			
			-- derive the width of the visible image mask
			set visbleImageMaskWidth to visbleImageMaskBottomRightHorizontalOffset - visbleImageMaskTopLeftHorizontalOffset
			
			log "visbleImageMaskWidth: " & visbleImageMaskWidth
			
			-- derive the top left vertical offset of the visible image mask
			if imageMaskTopLeftVerticalOffset is less than 0 then
				set visbleImageMaskTopLeftVerticalOffset to 0
			else
				set visbleImageMaskTopLeftVerticalOffset to imageMaskTopLeftVerticalOffset
			end if
			
			log "visbleImageMaskTopLeftVerticalOffset: " & visbleImageMaskTopLeftVerticalOffset
			
			-- derive the bottom right vertical offset of the visible image mask
			set imageMaskBottomRightVerticalOffset to imageMaskTopLeftVerticalOffset + imageMaskHeight
			if imageMaskBottomRightVerticalOffset is greater than documentHeight then
				set visibleImageMaskBottomRightVerticalOffset to documentHeight
			else
				set visibleImageMaskBottomRightVerticalOffset to imageMaskBottomRightVerticalOffset
			end if
			
			log "visibleImageMaskBottomRightVerticalOffset: " & visibleImageMaskBottomRightVerticalOffset
			
			-- derive the height of the visible image mask
			set visbleImageMaskHeight to visibleImageMaskBottomRightVerticalOffset - visbleImageMaskTopLeftVerticalOffset
			
			log "visbleImageMaskHeight: " & visbleImageMaskHeight
			
			-- return bounds of the visible image mask
			return {visbleImageMaskTopLeftHorizontalOffset, visbleImageMaskTopLeftVerticalOffset, visbleImageMaskBottomRightHorizontalOffset, visibleImageMaskBottomRightVerticalOffset}
		end tell
	end tell
end deriveBoundsOfVisibleImageMaskFor

(* QR CODE *)
on convertClipboardToQRImageAndAddToSlide(targetMinimumDimension)
	-- set targetMinimumDimension to 400
	try
		tell application "Keynote Creator Studio"
			activate
			if playing is true then tell the front document to stop
			if not (exists document 1) then error number -128
			if (clipboard info for «class utf8») is not {} then
				set clipboardText to (get the clipboard as «class utf8»)
			else
				error "There is no text on the clipboard to convert into a QR code image."
			end if
		end tell
		
		-- derive a file path for the created image file
		set theUUID to current application's NSUUID's UUID()'s UUIDString()
		set fileManager to current application's NSFileManager's defaultManager()
		set theURL to (fileManager's URLsForDirectory:(current application's NSPicturesDirectory) inDomains:(current application's NSUserDomainMask))'s firstObject()
		set the targetItemHFSPath to (theURL as string) & (theUUID as string) & ".jpg"
		set targetItemPOSIXPath to POSIX path of targetItemHFSPath
		
		set thisImageObject to my createFullSizeQRCodeImageObjectForString(clipboardText)
		my writeNSImageObjectToFileAsJPEG(thisImageObject, targetItemPOSIXPath, false)
		
		set the targetFile to targetItemHFSPath as alias
		tell application "Keynote Creator Studio"
			activate
			if not (exists document 1) then
				make new document
			end if
			tell front document
				set documentWidth to the width of it
				set documentHeight to the height of it
				tell current slide
					-- add the image to the slide and size to desired dimension
					set thisImage to make new image with properties {file:targetFile, width:targetMinimumDimension, height:targetMinimumDimension}
					-- center the added image on the slide
					set the position of thisImage to {(documentWidth - targetMinimumDimension) div 2, (documentHeight - targetMinimumDimension) div 2}
				end tell
			end tell
		end tell
		
		-- SInce the image is automatically added to document bundle, move the source image file to trash
		set fileManager to current application's NSFileManager's defaultManager()
		set thisPOSIXPath to current application's NSString's stringWithString:targetItemPOSIXPath
		set resultingURL to missing value
		set URLOfItemToTrash to (current application's |NSURL|'s fileURLWithPath:thisPOSIXPath)
		(fileManager's trashItemAtURL:URLOfItemToTrash resultingItemURL:resultingURL |error|:(missing value))
		
		-- say "Done!"
	on error errorMessage number errorNumber
		if errorNumber is not -128 then
			set spokenErrorTitle to "I was unable to complete your request: "
			set cfgutil to "/usr/bin/say"
			set theTask to (current application's NSTask's launchedTaskWithLaunchPath:cfgutil arguments:{(spokenErrorTitle & errorMessage)})
			tell application (POSIX path of (path to frontmost application))
				activate
				display alert "Unable to Complete Request:" message errorMessage buttons {"Cancel"} default button 1
			end tell
			theTask's terminate()
		end if
	end try
end convertClipboardToQRImageAndAddToSlide

on turnContentsOfSelectedTextItemIntoQRImageAndAddToSlide(targetMinimumDimension)
	tell application id "com.apple.iWork.Keynote"
		activate
		if «class Plng» is true then
			tell the front document to «event KnststoP»
		else
			if not (exists document 1) then
				my displaySpokenErrorAlert("KEYNOTE_NO_DOCUMENT", "com.apple.iWork.Keynote")
				error number -128
			end if
		end if
		set theseSlideItems to my getSelectedSlideItems()
		if the (count of theseSlideItems) is not 1 then
			my displaySpokenErrorAlert("SELECT_ONE_TEXT_ITEM", "com.apple.iWork.Keynote")
			error number -128
		end if
		set thisSlideItem to item 1 of theseSlideItems
		if (the class of thisSlideItem) is not «class shtx» then
			my displaySpokenErrorAlert("SELECT_ONE_TEXT_ITEM", "com.apple.iWork.Keynote")
			error number -128
		end if
		set thisText to the «class pDTx» of thisSlideItem
		if thisText is "" then
			my displaySpokenErrorAlert("TEXT_ITEM_HAS_NO_TEXT", "com.apple.iWork.Keynote")
			error number -128
		end if
	end tell
	-- derive a file path for the created image file
	set theUUID to current application's NSUUID's UUID()'s UUIDString()
	set fileManager to current application's NSFileManager's defaultManager()
	set theURL to (fileManager's URLsForDirectory:(current application's NSPicturesDirectory) inDomains:(current application's NSUserDomainMask))'s firstObject()
	set the targetItemHFSPath to (theURL as string) & (theUUID as string) & ".jpg"
	set targetItemPOSIXPath to POSIX path of targetItemHFSPath
	
	set thisImageObject to my createFullSizeQRCodeImageObjectForString(thisText)
	my writeNSImageObjectToFileAsJPEG(thisImageObject, targetItemPOSIXPath, false)
	
	set the targetFile to targetItemHFSPath as alias
	tell application id "com.apple.iWork.Keynote"
		activate
		if not (exists document 1) then
			make new document
		end if
		tell front document
			set documentWidth to the «class sitw» of it
			set documentHeight to the «class sith» of it
			tell «class crsl»
				-- add the image to the slide and size to desired dimension
				set thisImage to make new «class imag» with properties {file:targetFile, «class sitw»:targetMinimumDimension, «class sith»:targetMinimumDimension}
				-- center the added image on the slide
				set the «class sipo» of thisImage to {(documentWidth - targetMinimumDimension) div 2, (documentHeight - targetMinimumDimension) div 2}
			end tell
		end tell
	end tell
	
	-- SInce the image is automatically added to document bundle, move the source image file to trash
	set fileManager to current application's NSFileManager's defaultManager()
	set thisPOSIXPath to current application's NSString's stringWithString:targetItemPOSIXPath
	set resultingURL to missing value
	set URLOfItemToTrash to (current application's |NSURL|'s fileURLWithPath:thisPOSIXPath)
	(fileManager's trashItemAtURL:URLOfItemToTrash resultingItemURL:resultingURL |error|:(missing value))
	
end turnContentsOfSelectedTextItemIntoQRImageAndAddToSlide

on overlayLocationURLQRCodeOnSelectedImage(mapSoureIndicator)
	try
		tell application id "com.apple.iWork.Keynote"
			activate
			if «class Plng» is true then
				tell the front document to «event KnststoP»
			else
				if not (exists document 1) then
					error "KEYNOTE_NO_DOCUMENT"
				end if
			end if
			tell front document
				tell «class crsl»
					set theseImages to every «class imag»
					set imageCount to the count of theseImages
					if imageCount is 1 then
						set thisImage to item 1 of theseImages
					else
						-- GET SELECTED IMAGE
						set thisImage to my getSelectedKeynoteImage()
					end if
				end tell
			end tell
		end tell
		-- RETRIEVE PHOTOS ID FROM IMAGE NAME
		set thisPhotosID to retrievePhotosIDForKeynoteImage(thisImage)
		if thisPhotosID is false then
			error "IMAGE_NOT_IN_LIBRARY"
		end if
		-- GET LOCATION DATA FROM PHOTOS
		copy locationForMediaItemByID(thisPhotosID) to {aLongitude, aLatitude}
		if aLongitude is missing value then
			error "NO_LOCATION_DATA"
		else
			if mapSoureIndicator is 0 then -- Apple Maps
				set mapURLString to "http://maps.apple.com/?ll=" & aLongitude & "," & aLatitude
			else if mapSoureIndicator is 1 then -- Google Maps for iOS app
				set mapURLString to "comgooglemaps://?center=" & aLongitude & "," & aLatitude & "&" & "zoom=14"
			else -- Google Maps browser
				set mapURLString to "https://www.google.com/maps/@" & aLongitude & "," & aLatitude & "," & "19z"
			end if
			log mapURLString
		end if
		-- derive a file path for the created image file
		set theUUID to current application's NSUUID's UUID()'s UUIDString()
		set fileManager to current application's NSFileManager's defaultManager()
		set theURL to (fileManager's URLsForDirectory:(current application's NSPicturesDirectory) inDomains:(current application's NSUserDomainMask))'s firstObject()
		set the targetItemHFSPath to (theURL as string) & (theUUID as string) & ".jpg"
		set targetItemPOSIXPath to POSIX path of targetItemHFSPath
		
		set thisImageObject to my createFullSizeQRCodeImageObjectForString(mapURLString)
		my writeNSImageObjectToFileAsJPEG(thisImageObject, targetItemPOSIXPath, false)
		
		set the targetFile to targetItemHFSPath as alias
		tell application id "com.apple.iWork.Keynote"
			activate
			if not (exists document 1) then
				make new document
			end if
			tell front document
				set documentWidth to the «class sitw» of it
				set documentHeight to the «class sith» of it
				set targetMinimumDimension to documentHeight div 5
				tell «class crsl»
					-- add the image to the slide and size to desired dimension
					set thisImage to make new «class imag» with properties {file:targetFile, «class sitw»:targetMinimumDimension, «class sith»:targetMinimumDimension}
					-- place the added image on the slide at the bottom right
					set the «class sipo» of thisImage to {(documentWidth - targetMinimumDimension), (documentHeight - targetMinimumDimension)}
				end tell
			end tell
		end tell
		
		-- SInce the image is automatically added to document bundle, move the source image file to trash
		set fileManager to current application's NSFileManager's defaultManager()
		set thisPOSIXPath to current application's NSString's stringWithString:targetItemPOSIXPath
		set resultingURL to missing value
		set URLOfItemToTrash to (current application's |NSURL|'s fileURLWithPath:thisPOSIXPath)
		(fileManager's trashItemAtURL:URLOfItemToTrash resultingItemURL:resultingURL |error|:(missing value))
		
	on error errorMessage number errorNumber
		if errorNumber is not -128 then
			my displaySpokenErrorAlert(errorMessage, "com.apple.iWork.Keynote")
		end if
		error number -128
	end try
end overlayLocationURLQRCodeOnSelectedImage

(* QR CODE SUPPORT ROUTINES *)

on createFullSizeQRCodeImageObjectForString(thisString)
	-- returns a full-size NSImage object
	
	set thisString to current application's NSString's stringWithString:thisString
	
	set thisData to thisString's dataUsingEncoding:(current application's NSUTF8StringEncoding)
	
	set anImageFilter to current application's CIFilter's filterWithName:"CIQRCodeGenerator"
	anImageFilter's setDefaults()
	anImageFilter's setValue:thisData forKey:"inputMessage"
	anImageFilter's setValue:"L" forKey:"inputCorrectionLevel"
	
	set baseImage to anImageFilter's outputImage()
	
	set aTransform to current application's CGAffineTransform's CGAffineTransformMakeScale(100.0, 100.0)
	
	set outputImage to baseImage's imageByApplyingTransform:aTransform
	
	set imageRepresentation to current application's NSCIImageRep's imageRepWithCIImage:outputImage
	
	set resultingImageObject to current application's NSImage's alloc()'s initWithSize:(imageRepresentation's |size|())
	
	resultingImageObject's addRepresentation:imageRepresentation
	
	return resultingImageObject
end createFullSizeQRCodeImageObjectForString

on createScaledQRCodeImageObjectForString(thisString, targetWidth, targetHeight)
	-- returns a scaled NSImage object
	
	set thisString to current application's NSString's stringWithString:thisString
	
	set thisData to thisString's dataUsingEncoding:(current application's NSUTF8StringEncoding)
	
	set anImageFilter to current application's CIFilter's filterWithName:"CIQRCodeGenerator"
	anImageFilter's setDefaults()
	anImageFilter's setValue:thisData forKey:"inputMessage"
	anImageFilter's setValue:"L" forKey:"inputCorrectionLevel"
	
	set baseImage to anImageFilter's outputImage()
	
	set baseImageSize to baseImage's extent()'s |size|()
	
	set xScale to targetWidth / (baseImageSize's width())
	set yScale to targetHeight / (baseImageSize's height())
	
	set aTransform to current application's CGAffineTransform's CGAffineTransformMakeScale(xScale, yScale)
	
	set outputImage to baseImage's imageByApplyingTransform:aTransform
	
	set imageRepresentation to current application's NSCIImageRep's imageRepWithCIImage:outputImage
	
	set resultingImageObject to current application's NSImage's alloc()'s initWithSize:(imageRepresentation's |size|())
	
	resultingImageObject's addRepresentation:imageRepresentation
	
	return resultingImageObject
end createScaledQRCodeImageObjectForString

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

(* PRESENTER NOTES *)
on speakPresenterNotesOfCurrentSlide()
	tell application id "com.apple.iWork.Keynote"
		if not (exists document 1) then
			my displaySpokenErrorAlert("KEYNOTE_NO_DOCUMENT", "com.apple.iWork.Keynote")
			error number -128
		end if
		tell front document
			set theseNotes to (the «class ksnt» of the «class crsl»)
			if theseNotes is "" then
				my displaySpokenErrorAlert("KEYNOTE_NO_NOTES_FOR_SLIDE", "com.apple.iWork.Keynote")
				error number -128
			else
				my speakWithMutedInput(theseNotes)
			end if
		end tell
	end tell
end speakPresenterNotesOfCurrentSlide

on stopSpeaking()
	set stopSpeakingAlert to getLocalizedStringForKey("KEYNOTE_STOP_SPEAKING_ALERT")
	say stopSpeakingAlert with stopping current speech
end stopSpeaking

on extractKeynoteSpeakerNotes()
	tell application id "com.apple.iWork.Keynote"
		if not (exists document 1) then
			my displaySpokenErrorAlert("KEYNOTE_NO_DOCUMENT", "com.apple.iWork.Keynote")
			error number -128
		end if
		tell front document
			set docName to the name of it
			set combinedPresenterNotes to my getLocalizedStringForKey("WORDS_FOR_PRESENTER_NOTES") & ": " & docName
			set theseSlides to every «class KnSd» whose «class Kskp» is false
			set localizedSlideWord to my getLocalizedStringForKey("WORD_FOR_SLIDE")
			repeat with i from 1 to the count of theseSlides
				set thisSlide to item i of theseSlides
				set thisSlideNotes to «class ksnt» of thisSlide
				if thisSlideNotes is not "" then
					set thisSlideNumber to («class KSdN» of thisSlide) as string
					set thisSlideEntry to localizedSlideWord & space & thisSlideNumber & " • " & thisSlideNotes
					set combinedPresenterNotes to combinedPresenterNotes & linefeed & linefeed & thisSlideEntry
				end if
			end repeat
		end tell
	end tell
	return combinedPresenterNotes
end extractKeynoteSpeakerNotes

on addPresenterNotesToOutgoingMailMessage()
	tell application id "com.apple.iWork.Keynote"
		if not (exists document 1) then
			my displaySpokenErrorAlert("KEYNOTE_NO_DOCUMENT", "com.apple.iWork.Keynote")
			error number -128
		end if
		tell front document
			set docName to the name of it
			set messageSubject to my getLocalizedStringForKey("WORDS_FOR_PRESENTER_NOTES") & ": " & docName
		end tell
	end tell
	set extractedNotes to extractKeynoteSpeakerNotes()
	tell script "DC-Mail"
		createNewOutgoingMailMessage(messageSubject, extractedNotes, {}, true)
	end tell
	return true
end addPresenterNotesToOutgoingMailMessage

on addPresenterNotesToNewPagesDocument()
	tell application id "com.apple.iWork.Keynote"
		if not (exists document 1) then
			my displaySpokenErrorAlert("KEYNOTE_NO_DOCUMENT", "com.apple.iWork.Keynote")
			error number -128
		end if
		tell front document
			set docName to the name of it
			set messageSubject to my getLocalizedStringForKey("WORDS_FOR_PRESENTER_NOTES") & ": " & docName
		end tell
	end tell
	set extractedNotes to extractKeynoteSpeakerNotes()
	tell script "DC-Pages"
		createNewPagesWordProcessingDocument(extractedNotes, true)
	end tell
	return true
end addPresenterNotesToNewPagesDocument

on renderPresenterNotesOfCurrentSlideToAudioFileAndImport()
	try
		tell application id "com.apple.iWork.Keynote"
			activate
			if not (exists document 1) then
				error "KEYNOTE_NO_DOCUMENT"
			end if
			if «class Plng» is true then
				tell the front document to «event KnststoP»
			end if
			tell front document
				tell the «class crsl»
					set thisSlideNumber to the «class KSdN»
					set thisSlidesNotes to «class ksnt»
					if thisSlidesNotes is "" then
						error "CURRENT_SLIDE_NO_PRESENTER_NOTES"
					end if
					set thisAudioFile to my renderAndEncode(thisSlidesNotes, thisSlideNumber)
					if thisAudioFile is not false then
						set thisAudioClip to make new «class imag» with properties {file:thisAudioFile}
						my deleteFile(thisAudioFile)
					end if
				end tell
			end tell
		end tell
		say (my getLocalizedStringForKey("SUCCESSFUL_COMPLETION_PHRASE"))
	on error errorMessage number errorNumber
		if errorNumber is not -128 then
			my displaySpokenErrorAlert(errorMessage, "com.apple.iWork.Keynote")
		end if
		error number -128
	end try
end renderPresenterNotesOfCurrentSlideToAudioFileAndImport

on renderPresenterNotesOfAllSlidesToAudioFilesAndImport()
	try
		tell application id "com.apple.iWork.Keynote"
			activate
			if not (exists document 1) then
				error "KEYNOTE_NO_DOCUMENT"
			end if
			if «class Plng» is true then
				tell the front document to «event KnststoP»
			end if
			tell front document
				repeat with i from 1 to the count of every «class KnSd»
					set thisSlide to «class KnSd» i
					if «class Kskp» of thisSlide is false then
						tell thisSlide
							set thisSlideNumber to the «class KSdN»
							set thisSlidesNotes to «class ksnt»
							if thisSlidesNotes is not "" then
								set thisAudioFile to my renderAndEncode(thisSlidesNotes, thisSlideNumber)
								if thisAudioFile is not false then
									set thisAudioClip to make new «class imag» with properties {file:thisAudioFile}
									my deleteFile(thisAudioFile)
								end if
							end if
						end tell
					end if
				end repeat
			end tell
		end tell
		say (my getLocalizedStringForKey("SUCCESSFUL_COMPLETION_PHRASE"))
	on error errorMessage number errorNumber
		if errorNumber is not -128 then
			my displaySpokenErrorAlert(errorMessage, "com.apple.iWork.Keynote")
		end if
		error number -128
	end try
end renderPresenterNotesOfAllSlidesToAudioFilesAndImport

(* AUDIO RENDERING SUPPORT HANDLERS *)

on deleteFile(thisFileHFSAlias)
	set thisFilePOSIXPath to the POSIX path of thisFileHFSAlias
	do shell script "rm -f " & (quoted form of thisFilePOSIXPath)
end deleteFile

on renderAndEncode(thisSlidesNotes, thisSlideNumber)
	if thisSlidesNotes is "" then
		return false
	else
		-- get the path to the temp folder
		set the temporaryItemsFolder to the POSIX path of (path to temporary items)
		-- derive unique names for the audio files
		set thisTempName to (do shell script "uuidgen")
		set audioAIFFFileName to ¬
			"SLIDE-" & thisSlideNumber & "-" & thisTempName & ".aiff"
		set audioMPEGFileName to ¬
			"SLIDE-" & thisSlideNumber & "-" & thisTempName & ".m4a"
		-- construct the paths to the files to be created
		set targetAIFFFilePath to temporaryItemsFolder & audioAIFFFileName
		set targetMPEGFilePath to temporaryItemsFolder & audioMPEGFileName
		-- render text to AIFF audio file
		do shell script "say" & space & "-o" & space & ¬
			quoted form of targetAIFFFilePath & space & quoted form of thisSlidesNotes
		-- encode audio file to MPEG
		do shell script "afconvert -f 'm4af' -d 'aac ' -s 1 " & ¬
			(quoted form of targetAIFFFilePath) & space & (quoted form of targetMPEGFilePath)
		-- delete source audio file
		do shell script "rm -f " & (quoted form of targetAIFFFilePath)
		-- return reference to encoded audio file
		return (targetMPEGFilePath as POSIX file as alias)
	end if
end renderAndEncode

(* AUDIO CLIPS HANDLERS *)

on deleteAllAudioClipsInfFrontDocument()
	try
		tell application id "com.apple.iWork.Keynote"
			activate
			if not (exists document 1) then
				my displaySpokenErrorAlert("KEYNOTE_NO_DOCUMENT", "com.apple.iWork.Keynote")
				error number -128
			end if
			if my askForConfirmation("AUDIO_DELETE_CONFIRMATION_MESSAGE", "DELETE_BUTTON_TITLE", "STOP_BUTTON_TITLE", "com.apple.iWork.Keynote") is true then
				tell the front document
					delete every «class shau» of every «class KnSd»
				end tell
				my announceCompletion()
			end if
		end tell
	on error errorMessage number errorNumber
		if errorNumber is not -128 then
			my displaySpokenErrorAlert(errorMessage, "com.apple.iWork.Keynote")
		end if
		error number -128
	end try
end deleteAllAudioClipsInfFrontDocument

on setVolumeOfAllAudioClipsInfFrontDocument(percentageValue)
	try
		set percentageValue to my integerValueForString(percentageValue)
		if percentageValue is less than 0 or percentageValue is greater than 100 then
			my displaySpokenErrorAlert("INVALID_SIZING_DIMENSION", "com.apple.iWork.Keynote")
			error number -128
		end if
		tell application id "com.apple.iWork.Keynote"
			activate
			if not (exists document 1) then
				my displaySpokenErrorAlert("KEYNOTE_NO_DOCUMENT", "com.apple.iWork.Keynote")
				error number -128
			end if
			tell the front document
				set «class avol» of every «class shau» of every «class KnSd» to percentageValue
			end tell
		end tell
		my announceCompletion()
	on error errorMessage number errorNumber
		if errorNumber is not -128 then
			my displaySpokenErrorAlert(errorMessage, "com.apple.iWork.Keynote")
		end if
		error number -128
	end try
end setVolumeOfAllAudioClipsInfFrontDocument

(* IMAGES *)

on scaleSelectedImageToFitSlideWidthAndCenterVertically()
	set thisImage to getSelectedKeynoteImage()
	scaleImageToFitSlideWidthAndCenterVertically(thisImage)
end scaleSelectedImageToFitSlideWidthAndCenterVertically

on scaleImageToFitSlideWidthAndCenterVertically(thisImage)
	try
		tell application id "com.apple.iWork.Keynote"
			activate
			tell front document
				set documentWidth to its «class sitw»
				set documentHeight to its «class sith»
				set «class sitw» of thisImage to documentWidth
				set newImageHeight to the «class sith» of thisImage
				set y to (documentHeight - newImageHeight) div 2
				set «class sipo» of thisImage to {0, y}
			end tell
		end tell
	on error errorMessage number errorNumber
		if errorNumber is not -128 then
			my displaySpokenErrorAlert(errorMessage, "com.apple.iWork.Keynote")
		end if
		error number -128
	end try
end scaleImageToFitSlideWidthAndCenterVertically

on scaleSelectedImageToFitSlideHeightAndCenterHorizontally()
	set thisImage to getSelectedKeynoteImage()
	scaleImageToFitSlideHeightAndCenterHorizontally(thisImage)
end scaleSelectedImageToFitSlideHeightAndCenterHorizontally

on scaleImageToFitSlideHeightAndCenterHorizontally(thisImage)
	try
		tell application id "com.apple.iWork.Keynote"
			activate
			tell front document
				set documentWidth to its «class sitw»
				set documentHeight to its «class sith»
				set «class sith» of thisImage to documentHeight
				set newImageWidth to the «class sitw» of thisImage
				set x to (documentWidth - newImageWidth) div 2
				set «class sipo» of thisImage to {x, 0}
			end tell
		end tell
	on error errorMessage number errorNumber
		if errorNumber is not -128 then
			my displaySpokenErrorAlert(errorMessage, "com.apple.iWork.Keynote")
		end if
		error number -128
	end try
end scaleImageToFitSlideHeightAndCenterHorizontally

on chooseFileForSelectedImage()
	try
		tell application id "com.apple.iWork.Keynote"
			activate
			if «class Plng» is true then
				beep
				error number -128
			else
				if not (exists document 1) then
					error "KEYNOTE_NO_DOCUMENT"
				end if
			end if
			tell front document
				tell «class crsl»
					set theseImages to my getSelectedKeynoteImages()
					if theseImages is {} then
						if exists «class imag» 1 then
							set thisImage to «class imag» 1
							my assistImportForImage(thisImage, true)
						else
							error "NO_IMAGES_ON_SLIDE"
						end if
					else
						repeat with i from 1 to the count of theseImages
							set thisImage to item i of theseImages
							my assistImportForImage(thisImage, true)
						end repeat
					end if
				end tell
			end tell
		end tell
	on error errorMessage number errorNumber
		if errorNumber is not -128 then
			my displaySpokenErrorAlert(errorMessage, "com.apple.iWork.Keynote")
		end if
		error number -128
	end try
end chooseFileForSelectedImage

on getSelectedKeynoteImages()
	try
		tell application id "com.apple.iWork.Keynote"
			set selectedItems to my getSelectedSlideItems()
			set itemCount to count of selectedItems
			set imageItemRefs to {}
			repeat with i from 1 to itemCount
				set thisItem to item 1 of selectedItems
				if the class of thisItem is «class imag» then
					set the end of imageItemRefs to thisItem
				end if
			end repeat
			return imageItemRefs
		end tell
	on error errorMessage number errorNumber
		if errorNumber is not -128 then
			my displaySpokenErrorAlert(errorMessage, "com.apple.iWork.Keynote")
		end if
		error number -128
	end try
end getSelectedKeynoteImages

on getAllImagesOnCurrentSlide()
	try
		tell application id "com.apple.iWork.Keynote"
			activate
			if «class Plng» is true then
				beep
				error number -128
			else
				if not (exists document 1) then
					error "KEYNOTE_NO_DOCUMENT"
				end if
			end if
			tell front document
				tell «class crsl»
					set theseImages to every «class imag»
					return theseImages
				end tell
			end tell
		end tell
	on error errorMessage number errorNumber
		if errorNumber is not -128 then
			my displaySpokenErrorAlert(errorMessage, "com.apple.iWork.Keynote")
		end if
		error number -128
	end try
end getAllImagesOnCurrentSlide

on assistWithImportForSelectedImagesOnCurrentSlide()
	try
		tell application id "com.apple.iWork.Keynote"
			activate
			if «class Plng» is true then
				beep
				error number -128
			else
				if not (exists document 1) then
					error "KEYNOTE_NO_DOCUMENT"
				end if
			end if
			tell front document
				tell «class crsl»
					set selectedImages to my getSelectedKeynoteImages()
					if selectedImages is {} then
						-- if no images are selected then import into all
						my assistWithImportForAllImagesOnCurrentSlide()
					else -- import into only the selected images
						repeat with i from 1 to the count of selectedImages
							set thisImage to item i of selectedImages
							my assistImportForImage(thisImage, true)
						end repeat
					end if
				end tell
			end tell
		end tell
	on error errorMessage number errorNumber
		if errorNumber is not -128 then
			my displaySpokenErrorAlert(errorMessage, "com.apple.iWork.Keynote")
		end if
		error number -128
	end try
end assistWithImportForSelectedImagesOnCurrentSlide

on assistWithImportForAllImagesOnCurrentSlide()
	try
		tell application id "com.apple.iWork.Keynote"
			activate
			if «class Plng» is true then
				beep
				error number -128
			else
				if not (exists document 1) then
					error "KEYNOTE_NO_DOCUMENT"
				end if
			end if
			tell front document
				tell «class crsl»
					set imageCount to the count of every «class imag»
					if imageCount is 0 then
						error "NO_IMAGES_ON_SLIDE"
					end if
					repeat with i from 1 to the imageCount
						my assistImportForImageByIndex(i, true)
						tell current application
							do shell script "sleep 0.5"
						end tell
					end repeat
				end tell
			end tell
		end tell
	on error errorMessage number errorNumber
		if errorNumber is not -128 then
			my displaySpokenErrorAlert(errorMessage, "com.apple.iWork.Keynote")
		end if
		error number -128
	end try
end assistWithImportForAllImagesOnCurrentSlide

on assistImportForImage(thisImage, shouldDisplaySlideFitView)
	try
		tell application id "com.apple.iWork.Keynote"
			activate
			if «class Plng» is true then
				beep
				error number -128
			else
				if not (exists document 1) then
					error "KEYNOTE_NO_DOCUMENT"
				end if
			end if
			tell front document
				if «class pLck» of thisImage is true then
					error "IMAGE_LOCKED" & space & thisIndex
				end if
				set currentImageName to the «class atfn» of thisImage
				-- select the image
				set «class sipo» of thisImage to «class sipo» of thisImage
				-- zoom the selection
				tell application "System Events"
					keystroke "0" using {shift down, command down}
				end tell
				tell current application
					do shell script "sleep 0.5"
				end tell
				set dialogPrompt to (my getLocalizedStringForKey("CHOOSE_FILE_FOR_IMAGE_PROMPT")) & space & "“" & currentImageName & "”"
				set chosenImageFile to (choose file of type "public.image" with prompt dialogPrompt default location (path to pictures folder))
				set the «class atfn» of thisImage to chosenImageFile
			end tell
		end tell
		if shouldDisplaySlideFitView is true then my scaleLayoutViewToWrapSlide()
	on error errorMessage number errorNumber
		if shouldDisplaySlideFitView is true then my scaleLayoutViewToWrapSlide()
		if errorNumber is not -128 then
			my displaySpokenErrorAlert(errorMessage, "com.apple.iWork.Keynote")
		end if
		error number -128
	end try
end assistImportForImage

on assistImportForImageByIndex(thisIndex, shouldDisplaySlideFitView)
	try
		tell application id "com.apple.iWork.Keynote"
			activate
			if «class Plng» is true then
				beep
				error number -128
			else
				if not (exists document 1) then
					error "KEYNOTE_NO_DOCUMENT"
				end if
			end if
			tell front document
				tell «class crsl»
					set imageCount to the count of every «class imag»
					if imageCount is not greater than or equal to thisIndex then
						error "NO_IMAGE_OF_INDEX" & space & thisIndex
					end if
					if «class pLck» of «class imag» thisIndex is true then
						error "IMAGE_LOCKED" & space & thisIndex
					end if
					set currentImageName to the «class atfn» of «class imag» thisIndex
					-- select the image
					set «class sipo» of «class imag» thisIndex to «class sipo» of «class imag» thisIndex
					-- zoom the selection
					tell application "System Events"
						keystroke "0" using {shift down, command down}
					end tell
					tell current application
						do shell script "sleep 0.5"
					end tell
					set dialogPrompt to (my getLocalizedStringForKey("CHOOSE_FILE_FOR_IMAGE_PROMPT")) & space & "“" & currentImageName & "”"
					set chosenImageFile to (choose file of type "public.image" with prompt dialogPrompt default location (path to pictures folder))
					set the «class atfn» of «class imag» thisIndex to chosenImageFile
				end tell
			end tell
		end tell
		if shouldDisplaySlideFitView is true then my scaleLayoutViewToWrapSlide()
	on error errorMessage number errorNumber
		if shouldDisplaySlideFitView is true then my scaleLayoutViewToWrapSlide()
		if errorNumber is not -128 then
			my displaySpokenErrorAlert(errorMessage, "com.apple.iWork.Keynote")
		end if
		error number -128
	end try
end assistImportForImageByIndex

on exportAllImagesFromDocumentArchive()
	try
		set errorTitle to "SCRIPT ERROR"
		tell application id "com.apple.iWork.Keynote"
			activate
			if «class Plng» is true then
				beep
				error number -128
			else
				if not (exists document 1) then
					error "KEYNOTE_NO_DOCUMENT"
				end if
			end if
			set documentHasBeenModified to modified of document 1
			set documentName to the name of document 1
			if documentName ends with ".key" then
				set documentName to text 1 thru -5 of documentName
			end if
			set documentFile to the file of document 1
			if documentFile is missing value then
				set errorTitle to "UNSAVED DOCUMENT"
				error "UNSAVED_DOCUMENT"
			end if
			if (type identifier of (info for documentFile)) is not "com.apple.iwork.keynote.sffkey" then
				set errorTitle to "UNSUPPORTED FILE FORMAT"
				error "UNSUPPORTED_FILE_FORMAT"
			end if
			set documentFilePath to the POSIX path of documentFile
			if the (count of every «class imag» of every «class KnSd» of document 1) is 0 then
				set errorTitle to "NO IMAGES"
				error "DOCUMENT_NO_IMAGES"
			end if
			set targetFolder to (path to pictures folder)
			-- set targetFolder to (choose folder with prompt "Select a folder to contain the exported images directory:")
			set exportFolderName to documentName
		end tell
		tell application id "com.apple.finder"
			set loopIncrementor to 0
			repeat
				if (exists folder exportFolderName of targetFolder) then
					set loopIncrementor to loopIncrementor + 1
					set exportFolderName to (documentName & "-" & (loopIncrementor as string))
				else
					exit repeat
				end if
			end repeat
			set the exportFolder to make new folder at targetFolder with properties {name:exportFolderName}
			set the exportFolderPath to the POSIX path of (exportFolder as alias)
		end tell
		
		say (my getLocalizedStringForKey("BEGINNING_SCAN_FOR_IMAGES"))
		
		-- CHECK FOR A “DATA” FOLDER IN THE ARCHIVE
		if documentFilePath ends with "/" then set documentFilePath to text 1 thru -2 of documentFilePath
		set the commandString to "unzip -l" & space & (quoted form of documentFilePath) & " | grep 'Data/'"
		try
			set commandResult to (do shell script commandString)
		on error -- no Data
			error number -128
		end try
		set theseReferences to every paragraph of commandResult
		if theseReferences is {} then error number -128
		
		-- LOCATE IMAGES IN THE ARCHIVE
		set targetArchiveItems to {}
		repeat with i from 1 to the count of theseReferences
			set thisReference to item i of theseReferences
			if thisReference ends with ".jpg" or thisReference ends with ".png" or thisReference ends with ".tif" or thisReference ends with ".jpeg" or thisReference ends with ".tiff" then
				set the end of targetArchiveItems to thisReference
			end if
		end repeat
		if targetArchiveItems is {} then error number -128
		
		-- EXTRACT THE PATHS FROM THE RESULTS
		repeat with i from 1 to the count of targetArchiveItems
			set thisArchiveItem to item i of targetArchiveItems
			set x to the offset of " Data/" in thisArchiveItem
			set item i of targetArchiveItems to (text from (x + 1) to -1 of thisArchiveItem)
		end repeat
		
		log targetArchiveItems
		
		-- CONSTRUCT THE COMMAND ARGUMENT
		repeat with i from 1 to the count of targetArchiveItems
			set thisItem to item i of targetArchiveItems
			if i is 1 then
				set commandArgumentString to (the quoted form of thisItem)
			else
				set commandArgumentString to commandArgumentString & space & (the quoted form of thisItem)
			end if
		end repeat
		
		-- CONSTRUCT THE COMMAND STRING
		set the commandString to "unzip" & space & (quoted form of documentFilePath) & space & commandArgumentString & space & "-d" & space & (quoted form of exportFolderPath)
		
		say (my getLocalizedStringForKey("EXPORTING_IMAGES_TO_FILES"))
		
		-- EXECUTE THE COMMAND
		do shell script commandString
		
		-- SHOW RESULTS FOLDER
		do shell script "open " & (quoted form of (exportFolderPath & "/Data"))
		
		say (my getLocalizedStringForKey("SUCCESSFUL_COMPLETION_PHRASE"))
	on error errorMessage number errorNumber
		if errorNumber is not -128 then
			my displaySpokenErrorAlert(errorMessage, "com.apple.iWork.Keynote")
			error number -128
		end if
	end try
end exportAllImagesFromDocumentArchive

on setDescriptionForSelectedOrOnlyImage()
	tell application id "com.apple.iWork.Keynote"
		set thisImage to my getSelectedImageOrOnlyImage()
		set lockedFlag to «class pLck» of thisImage
		if lockedFlag is true then
			tell script "DC-Assistive-Keynote" to playUnlockingSound()
			set «class pLck» of thisImage to false
		end if
		set currentDescription to «class dscr» of thisImage
		set userPrompt to my getLocalizedStringForKey("ENTER_DESCRIPTION_PROMPT")
		say userPrompt without waiting until completion
		try
			--display dialog (userPrompt & ":") default answer currentDescription
			tell script "DC-Support"
				set dialogResult to displayTextEntryDialog(currentDescription, false)
			end tell
			set «class dscr» of thisImage to dialogResult --  text returned of the result
			if lockedFlag is true then
				tell script "DC-Assistive-Keynote" to playLockingSound()
				set «class pLck» of thisImage to true
			end if
			my announceCompletion()
		on error
			say "[[slnc 250]]" with stopping current speech
			if lockedFlag is true then
				tell script "DC-Assistive-Keynote" to playLockingSound()
				set «class pLck» of thisImage to true
			end if
		end try
	end tell
end setDescriptionForSelectedOrOnlyImage


(* PHOTOS-RELATED ACTIONS *)

on getSelectedKeynoteImage()
	try
		tell application id "com.apple.iWork.Keynote"
			set selectedItems to my getSelectedSlideItems()
			set itemCount to count of selectedItems
			if itemCount is not 1 then
				error "SELECT_SINGLE_IMAGE_SLIDE_ITEM"
			end if
			set thisItem to item 1 of selectedItems
			if the class of thisItem is not «class imag» then
				error "SELECT_SINGLE_IMAGE_SLIDE_ITEM"
			end if
			return thisItem
		end tell
	on error errorMessage number errorNumber
		if errorNumber is not -128 then
			my displaySpokenErrorAlert(errorMessage, "com.apple.iWork.Keynote")
		end if
		error number -128
	end try
end getSelectedKeynoteImage

on retrievePhotosDescriptionForKeynoteImage(thisImage)
	my logThis("retrievePhotosDescriptionForKeynoteImage(…)")
	set thisPhotosID to retrievePhotosIDForKeynoteImage(thisImage)
	if thisPhotosID is false then
		my displaySpokenErrorAlert("IMAGE_NOT_IN_LIBRARY", "com.apple.iWork.Keynote")
		error number -128
	end if
	set thisDescrption to descriptionForMediaItemByID(thisMediaItemID)
	if thisDescrption is false then
		my displaySpokenErrorAlert("IMAGE_NOT_IN_LIBRARY", "com.apple.iWork.Keynote")
		error number -128
	end if
	return thisDescrption
end retrievePhotosDescriptionForKeynoteImage

on showSelectedKeynoteImageInPhotos()
	my logThis("showSelectedKeynoteImageInPhotos()")
	set thisImage to my getSelectedKeynoteImage()
	set thisPhotosID to my retrievePhotosIDForKeynoteImage(thisImage)
	if thisPhotosID is false then
		my displaySpokenErrorAlert("IMAGE_NOT_IN_LIBRARY", "com.apple.iWork.Keynote")
		error number -128
	end if
	set thisMediaItem to my retrieveMediaItemForID(thisPhotosID)
	if thisMediaItem is false then
		my displaySpokenErrorAlert("IMAGE_NOT_IN_LIBRARY", "com.apple.iWork.Keynote")
		error number -128
	else
		my showInPhotos(thisMediaItem)
	end if
end showSelectedKeynoteImageInPhotos

on editSelectedKeynoteImageInPhotos()
	my logThis("editSelectedKeynoteImageInPhotos()")
	set thisImage to my getSelectedKeynoteImage()
	set thisPhotosID to my retrievePhotosIDForKeynoteImage(thisImage)
	if thisPhotosID is false then
		my displaySpokenErrorAlert("IMAGE_NOT_IN_LIBRARY", "com.apple.iWork.Keynote")
		error number -128
	end if
	set thisMediaItem to my retrieveMediaItemForID(thisPhotosID)
	if thisMediaItem is false then
		my displaySpokenErrorAlert("IMAGE_NOT_IN_LIBRARY", "com.apple.iWork.Keynote")
		error number -128
	else
		tell script "DC-Photos" to editImageByID(thisPhotosID)
	end if
end editSelectedKeynoteImageInPhotos

on showSelectedKeynoteImageInPhotosAndMaps()
	my logThis("showSelectedKeynoteImageInPhotosAndMaps()")
	set thisImage to my getSelectedKeynoteImage()
	set thisPhotosID to my retrievePhotosIDForKeynoteImage(thisImage)
	if thisPhotosID is false then
		my displaySpokenErrorAlert("IMAGE_NOT_IN_LIBRARY", "com.apple.iWork.Keynote")
		error number -128
	end if
	set thisMediaItem to my retrieveMediaItemForID(thisPhotosID)
	if thisMediaItem is false then
		my displaySpokenErrorAlert("IMAGE_NOT_IN_LIBRARY", "com.apple.iWork.Keynote")
		error number -128
	else
		my showInPhotos(thisMediaItem)
		my showPhotosItemsInMaps({thisMediaItem})
	end if
end showSelectedKeynoteImageInPhotosAndMaps

on showSelectedKeynoteImageInMaps()
	my logThis("showSelectedKeynoteImageInMaps()")
	set thisImage to my getSelectedKeynoteImage()
	set thisPhotosID to my retrievePhotosIDForKeynoteImage(thisImage)
	if thisPhotosID is false then
		my displaySpokenErrorAlert("IMAGE_NOT_IN_LIBRARY", "com.apple.iWork.Keynote")
		error number -128
	end if
	set thisMediaItem to my retrieveMediaItemForID(thisPhotosID)
	if thisMediaItem is false then
		my displaySpokenErrorAlert("IMAGE_NOT_IN_LIBRARY", "com.apple.iWork.Keynote")
		error number -128
	else
		my showPhotosItemsInMaps({thisMediaItem})
	end if
end showSelectedKeynoteImageInMaps

on showPhotosItemsInMaps(theseMediaItems)
	my logThis("showPhotosItemsInMaps(…)")
	set shouldShowTraffic to false
	set mapTypeIndicator to 1
	
	tell application id "com.apple.Photos"
		activate
		try
			set mediaItemsMetadata to {}
			repeat with i from 1 to the count of theseMediaItems
				set thisMediaItem to item i of theseMediaItems
				set thisLocation to the location of thisMediaItem
				if thisLocation is not {missing value, missing value} then
					set thisTitle to the name of thisMediaItem
					if thisTitle is missing value then
						set thisTitle to filename of thisMediaItem
					end if
					set thisID to the id of thisMediaItem
					set encodedID to my encodeReservedCharactersUsingPercentEncoding(thisID)
					set thisURL to ("photos:oneup/asset?assetUuid=" & encodedID & "&editMode=0")
					set the end of mediaItemsMetadata to {thisTitle, thisLocation, thisURL}
				end if
			end repeat
			if mediaItemsMetadata is {} then error "NO_LOCATION_DATA"
		on error errorMessage number errorNumber
			my displaySpokenErrorAlert(errorMessage, "com.apple.Photos")
			error number -128
		end try
	end tell
	
	tell application id "com.apple.Maps"
		activate
		try
			set theseMapItems to {}
			repeat with i from 1 to the count of mediaItemsMetadata
				set thisMetadata to item i of mediaItemsMetadata
				copy thisMetadata to {thisMediaItemTitle, thisLatitudeLongitudePair, thisMediaItemURL}
				log thisMediaItemURL
				copy thisLatitudeLongitudePair to {thisLatitude, thisLongitude}
				-- create a coordinate
				set aCoordinate to {latitude:thisLatitude, longitude:thisLongitude}
				-- create an address book dictionary 
				set aAddressBookDictionary to (current application's NSDictionary's dictionaryWithObjects:{} forKeys:{})
				(* To include actual address information: *)
				--set aAddressBookDictionary to (current application's NSDictionary's dictionaryWithObjects:{"28 Rose Street", "Hope Town", "State of Depression", "Utopia"} forKeys:{current application's kABAddressStreetKey, current application's kABAddressCityKey, current application's kABAddressStateKey, current application's kABAddressCountryKey})
				-- create a placemark using the coordinate and address dictionary
				set aPlacemark to (current application's MKPlacemark's alloc()'s initWithCoordinate:aCoordinate addressDictionary:aAddressBookDictionary)
				-- create a map item using the placemark
				set aMapItem to (current application's MKMapItem's alloc()'s initWithPlacemark:aPlacemark)
				set aMapItem's |name| to thisMediaItemTitle
				set aURL to (current application's NSURL's URLWithString:thisMediaItemURL)
				set aMapItem's |url| to aURL
				-- set aMapItem's |phoneNumber| to "555-555-5555"
				-- add the new map item to the list of map items
				set the end of theseMapItems to aMapItem
			end repeat
			-- create a dictionary of the map settings
			set mapOptionsDict to current application's NSDictionary's dictionaryWithObjects:{shouldShowTraffic, mapTypeIndicator} forKeys:{"MKLaunchOptionsShowsTraffic", "MKLaunchOptionsMapType"}
			-- display the location in the Maps application
			current application's MKMapItem's openMapsWithItems:theseMapItems launchOptions:mapOptionsDict
		on error errorMessage number errorNumber
			if errorNumber is not -128 then
				display alert "ERROR" message errorMessage buttons {"Cancel"} default button 1
			end if
			error number -128
		end try
	end tell
end showPhotosItemsInMaps

on encodeReservedCharactersUsingPercentEncoding(sourceText)
	-- create a Cocoa string from the passed AppleScript string, by calling the NSString class method stringWithString:
	set the sourceString to current application's NSString's stringWithString:sourceText
	-- apply the indicated transformation to the Cooca string
	set reservedCharacters to {"%", "!", "#", "$", "&", "'", "(", ")", "*", "+", ",", "/", ":", ";", "=", "?", "@", "[", "]"}
	set replacementStrings to {"%25", "%21", "%23", "%24", "%26", "%27", "%28", "%29", "%2A", "%2B", "%2C", "%2F", "%3A", "%3B", "%3D", "%3F", "%40", "%5B", "%5D"}
	repeat with i from 1 to the count of reservedCharacters
		set searchString to item i of reservedCharacters
		set replacementString to item i of replacementStrings
		set the sourceString to the (sourceString's stringByReplacingOccurrencesOfString:searchString withString:replacementString)
	end repeat
	-- coerce from Cocoa string to AppleScript string
	return (sourceString as string)
end encodeReservedCharactersUsingPercentEncoding

on updateSelectedImageInPresentation()
	set thisImage to my getSelectedKeynoteImage()
	set thisPhotosID to my retrievePhotosIDForKeynoteImage(thisImage)
	log ("thisPhotosID: " & thisPhotosID)
	if thisPhotosID is false then
		my displaySpokenErrorAlert("IMAGE_NOT_IN_LIBRARY", "com.apple.iWork.Keynote")
		error number -128
	end if
	set thisMediaItem to my retrieveMediaItemForID(thisPhotosID)
	if thisMediaItem is false then
		my displaySpokenErrorAlert("IMAGE_NOT_IN_LIBRARY", "com.apple.iWork.Keynote")
		error number -128
	else
		set thisDescription to descriptionForMediaItemByID(thisPhotosID)
		log ("thisDescription: " & thisDescription)
		if thisDescription is "" or thisDescription is missing value then -- if no description, use the image title
			log "Description is null string, using name"
			set thisDescription to nameForMediaItemByID(thisPhotosID)
			log ("thisDescription: " & thisDescription)
		end if
		log "data retrieved"
		(*
		tell script "Photos Utilities"
			set thisImageFile to quick export of {thisMediaItem} with ID as name
		end tell
		*)
		tell script "DC-Photos"
			set thisImageFile to quickExport({thisMediaItem}, true, false, 2, false, "", "", 3, 1)
		end tell
		tell application id "com.apple.iWork.Keynote"
			activate
			set «class atfn» of thisImage to thisImageFile
			set «class dscr» of thisImage to thisDescription
		end tell
		-- MOVE EXPORT FOLDER TO TRASH
		set fileManager to current application's NSFileManager's defaultManager()
		set thisPOSIXPath to the POSIX path of thisImageFile
		set thisPOSIXPath to current application's NSString's stringWithString:thisPOSIXPath
		set pathOfFolderToDelete to thisPOSIXPath's stringByDeletingLastPathComponent()
		set resultingURL to missing value
		set URLOfItemToTrash to (current application's |NSURL|'s fileURLWithPath:pathOfFolderToDelete)
		(fileManager's trashItemAtURL:URLOfItemToTrash resultingItemURL:resultingURL |error|:(missing value))
	end if
end updateSelectedImageInPresentation

(* PHOTOS SUPPORT HANDLERS FOR KEYNOTE *)

on retrievePhotosIDForKeynoteImage(thisImage)
	tell application id "com.apple.iWork.Keynote"
		set thisImageFileName to the «class atfn» of thisImage
		if thisImageFileName contains "-small" then
			set x to the offset of "-small" in thisImageFileName
			set thisItemID to text 1 thru (x - 1) of thisImageFileName
		else if thisImageFileName contains "." then
			set x to the offset of "." in thisImageFileName
			if x is not 0 then
				set thisItemID to text 1 thru (x - 1) of thisImageFileName
			else
				set thisItemID to thisImageFileName
			end if
		else
			set thisItemID to thisImageFileName
		end if
		tell application id "com.apple.Photos"
			set existenceStatus to (exists media item id thisItemID)
			if existenceStatus is false then
				return false
			else
				return thisItemID
			end if
		end tell
	end tell
end retrievePhotosIDForKeynoteImage

-- GET THE MEDIA ITEM OBJECT REFERENCE
on retrieveMediaItemForID(thisID)
	tell application "Photos"
		if exists (media item id thisID) then
			return media item id thisID
		else
			return false
		end if
	end tell
end retrieveMediaItemForID

-- GET THE NAME FOR THE MEDIA ITEM
on nameForMediaItemByID(thisMediaItemID)
	log ("nameForMediaItemByID(" & thisMediaItemID & ")")
	tell application id "com.apple.Photos"
		if not (exists media item id thisMediaItemID) then
			return false
		else
			log "getting name…"
			set thisName to (name of media item id thisMediaItemID)
			log ("thisName: " & thisName)
			if thisName is missing value or thisName is "" then
				--log ("name is null, getting file name")
				--set thisName to (filename of media item id thisMediaItemID)
				set thisName to ""
				log ("thisName: " & thisName)
			end if
			return thisName
		end if
	end tell
end nameForMediaItemByID

-- GET THE FILENAME FOR THE MEDIA ITEM
on filenameForMediaItemByID(thisMediaItemID)
	log ("filenameForMediaItemByID(" & thisMediaItemID & ")")
	tell application id "com.apple.Photos"
		if not (exists media item id thisMediaItemID) then
			return false
		else
			log "getting name…"
			set thisFilename to (getfilename of media item id thisMediaItemID)
			log ("thisFilename: " & thisFilename)
			return thisFilename
		end if
	end tell
end filenameForMediaItemByID

-- GET THE DESCRIPTION TEXT FOR THE MEDIA ITEM
on descriptionForMediaItemByID(thisMediaItemID)
	tell application id "com.apple.Photos"
		if not (exists media item id thisMediaItemID) then
			return false
		else
			set thisDescription to (description of media item id thisMediaItemID)
			if thisDescription is missing value then set thisDescription to ""
			return thisDescription
		end if
	end tell
end descriptionForMediaItemByID


-- GET THE LOCATION FOR THE MEDIA ITEM
on locationForMediaItemByID(thisMediaItemID)
	tell application id "com.apple.Photos"
		if not (exists media item id thisMediaItemID) then
			return false
		else
			return (location of media item id thisMediaItemID)
		end if
	end tell
end locationForMediaItemByID

-- SHOW A MEDIA ITEM ONE-UP IN PHOTOS
on showInPhotos(thisMediaItem)
	tell application id "com.apple.Photos"
		activate
		spotlight thisMediaItem
	end tell
end showInPhotos

(* AIRDROP CURRENT KEYNOTE FILE *)
on beginAirDropOfFrontmostPresentationFile()
	try
		tell application id "com.apple.iWork.Keynote"
			activate
			if not (exists document 1) then
				error "KEYNOTE_NO_DOCUMENT"
			end if
			set thisFile to file of document 1
			if thisFile is missing value then
				error "KEYNOTE_UNSAVED_DOCUMENT"
			end if
		end tell
		tell script "Dc-Workspace"
			beginAirDropSessionFor({thisFile})
		end tell
	on error errorMessage number errorNumber
		my displaySpokenErrorAlert(errorMessage, "com.apple.iWork.Keynote")
		error number -128
	end try
end beginAirDropOfFrontmostPresentationFile


(* GET SELECTED SLIDE ITEMS *)

on getSelectedSlideItems()
	try
		tell application id "com.apple.iWork.Keynote"
			activate
			if not (exists document 1) then
				my displaySpokenErrorAlert("KEYNOTE_NO_DOCUMENT", "com.apple.iWork.Keynote")
				error number -128
			end if
		end tell
		tell application "System Events"
			tell process "Keynote"
				set mainWindow to first window whose subrole is "AXStandardWindow"
				tell mainWindow
					set scrollAreaCount to the count of scroll areas
					set thisSlide to missing value
					repeat with i from 1 to the count of scroll areas
						tell scroll area i
							try
								set thisSlide to (first UI element whose role is "AXLayoutArea")
								exit repeat
							end try
						end tell
					end repeat
					tell thisSlide
						set itemIndexes to {}
						repeat with i from 1 to the count of UI elements
							set thisLayoutItem to UI element i
							if selected of thisLayoutItem is true then
								-- log (get properties of thisLayoutItem)
								set the end of itemIndexes to i
							end if
						end repeat
						if itemIndexes is {} then
							return {}
						end if
					end tell
				end tell
			end tell
		end tell
		tell application id "com.apple.iWork.Keynote"
			tell document 1
				tell «class crsl»
					set itemObjectReferences to {}
					repeat with i from 1 to the count of itemIndexes
						set thisIndex to item i of itemIndexes
						try
							log thisIndex
							set thisItem to («class fmti» thisIndex)
							-- log (get properties of thisItem)
							set the end of itemObjectReferences to thisItem
						end try
					end repeat
				end tell
			end tell
			return itemObjectReferences
		end tell
	on error errorMessage number errorNumber
		if errorNumber is not -128 then
			my displaySpokenErrorAlert(errorMessage, "com.apple.iWork.Keynote")
		end if
		error number -128
	end try
end getSelectedSlideItems

on getSelectedKeynoteTextItem()
	try
		tell application id "com.apple.iWork.Keynote"
			set selectedItems to my getSelectedSlideItems()
			return selectedItems
			set itemCount to count of selectedItems
			(*
			if itemCount is not 1 then
				error "SELECT_SINGLE_TEXT_ITEM"
			end if
			*)
			set thisItem to item 1 of selectedItems
			log thisItem
			if the class of thisItem is not «class shtx» then
				error "SELECT_SINGLE_TEXT_ITEM"
			end if
			return thisItem
		end tell
	on error errorMessage number errorNumber
		if errorNumber is not -128 then
			my displaySpokenErrorAlert(errorMessage, "com.apple.iWork.Keynote")
		end if
		error number -128
	end try
end getSelectedKeynoteTextItem

on getSelectedImageOrOnlyImage()
	try
		tell application id "com.apple.iWork.Keynote"
			activate
			if «class Plng» is true then
				tell document 1 to «event KnststoP»
			end if
			if not (exists document 1) then
				error "KEYNOTE_NO_DOCUMENT"
			end if
			set currentSelection to my getSelectedSlideItems()
			set selectionCount to the count of currentSelection
			if selectionCount is 0 then
				-- Check slide for images. If only one image, then return it.
				set currentImages to my getAllImagesOnCurrentSlide()
				set imageCount to the count of currentImages
				if imageCount is 0 then
					error "SLIDE_NO_IMAGES"
				else if imageCount is 1 then
					return (item 1 of currentImages)
				else
					error "SELECT_SINGLE_IMAGE_SLIDE_ITEM"
				end if
			else if selectionCount is 1 then
				set thisItem to item 1 of currentSelection
				if the class of thisItem is «class imag» then
					return thisItem
				else
					error "SELECT_SINGLE_IMAGE_SLIDE_ITEM"
				end if
			else
				set imageList to {}
				repeat with i from 1 to selectionCount
					set thisItem to item 1 of currentSelection
					if the class of thisItem is «class imag» then
						set the end of imageList to thisItem
					end if
				end repeat
				if the (count of imageList) is 0 then
					error "SLIDE_NO_IMAGES"
				else if the (count of imageList) is 1 then
					return (item 1 of imageList)
				else
					error "SELECT_SINGLE_IMAGE_SLIDE_ITEM"
				end if
			end if
		end tell
	on error errorMessage number errorNumber
		if errorNumber is not -128 then
			my displaySpokenErrorAlert(errorMessage, "com.apple.iWork.Keynote")
		end if
		error number -128
	end try
end getSelectedImageOrOnlyImage


(* SUPPORT HANDLERS *)

on returnBooleanValue(thisValue)
	try
		if class of thisValue is text then
			if thisValue is in {"0", "1"} then
				return ((thisValue as integer) as boolean)
			else if thisValue is in {"true", "false"} then
				return (thisValue as boolean)
			else
				return (thisValue as boolean)
			end if
		else if class of thisValue is integer then
			return (thisValue as boolean)
		else if class of thisValue is boolean then
			return thisValue
		else
			return (thisValue as boolean)
		end if
	on error
		set errorMsg to getLocalizedStringForKey("NOT_BOOLEAN_VALUE") & ": " & (thisValue as string)
		my displaySpokenErrorAlert(errorMsg, "com.apple.iWork.Keynote")
		error number -128
	end try
end returnBooleanValue

on removeFileExtension(thisString)
	set aString to current application's NSString's stringWithString:thisString
	return (aString's stringByDeletingPathExtension()) as text
end removeFileExtension

on replaceStringInString(sourceText, searchString, replacementString)
	set aString to current application's NSString's stringWithString:sourceText
	set resultString to the (aString's stringByReplacingOccurrencesOfString:searchString withString:replacementString)
	return resultString as text
end replaceStringInString

on getLocalizedStringForKey(thisKey)
	set thisBundlePath to (path to me)
	return (localized string thisKey in bundle thisBundlePath)
end getLocalizedStringForKey

on announceCompletion()
	say my getLocalizedStringForKey("SUCCESSFUL_COMPLETION_PHRASE")
end announceCompletion

on askForConfirmation(messageKey, approveButtonKey, disapproveButtonKey, appID)
	if appID is "" or appID is missing value then
		set aWorkspace to current application's NSWorkspace's sharedWorkspace
		set frontmostApp to aWorkspace's frontmostApplication
		set appID to (frontmostApp's bundleIdentifier) as text
	end if
	try
		set confirmationTitle to getLocalizedStringForKey("CONFIRMATION_TITLE")
		set confirmationMessage to getLocalizedStringForKey(messageKey)
		set approvalButtonTitle to getLocalizedStringForKey(approveButtonKey)
		set disapprovalButtonTitle to getLocalizedStringForKey(disapproveButtonKey)
		set cfgutil to "/usr/bin/say"
		set theTask to (current application's NSTask's launchedTaskWithLaunchPath:cfgutil arguments:{confirmationMessage})
		tell application id appID
			activate
			display alert confirmationTitle message confirmationMessage buttons {disapprovalButtonTitle, approvalButtonTitle}
			set userChoice to the button returned of the result
		end tell
		-- stop speaking
		theTask's terminate()
		if userChoice is approvalButtonTitle then
			return true
		else
			return false
		end if
	on error errorMessage
		log errorMessage
		-- stop speaking
		theTask's terminate()
		return false
	end try
end askForConfirmation

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

on speakThisWithDefaultVoice(thisString)
	set thisVoiceID to current application's NSSpeechSynthesizer's defaultVoice()
	set thisSpeechSynthesizer to current application's NSSpeechSynthesizer's alloc's initWithVoice:thisVoiceID
	thisSpeechSynthesizer's startSpeakingString:thisString
end speakThisWithDefaultVoice

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

