use framework "Foundation"
use framework "AppKit"
use framework "Automator"
--use framework "Quartz"
use scripting additions

property logEnabled : true
property sharingServiceIsOver : false
property defaultInputVolume : 75
property defaultVolumeIncrement : 25
property copyString : " copy" -- added to file names for copies; edit to suit your language

on getScreenDimensions()
	set screenRecord to (current application's NSScreen's mainScreen()'s frame()) as record
	copy (|size| of screenRecord) to {width:screenWidth, height:screenHeight}
	return {screenWidth, screenHeight}
end getScreenDimensions

on resizeDocumentWindow(appID, docID)
	copy getScreenDimensions() to {screenWidth, screenHeight}
	tell application id appID
		activate
		repeat with i from 1 to the count of windows
			set aWindow to window i
			if visible of aWindow is true then
				if document of aWindow is not missing value then
					set windowDocID to id of document of aWindow
					if windowDocID is not missing value then
						if windowDocID is docID then
							set the bounds of aWindow to {0, 22, screenWidth, screenHeight}
							return true
						end if
					end if
				end if
			end if
		end repeat
	end tell
	return false
end resizeDocumentWindow

(* FILE INFO HANDLERS *)

on tagsForFile(thisFileReference)
	set POSIXPath to getPOSIXPathForItem(thisFileReference)
	set theURL to current application's class "NSURL"'s fileURLWithPath:POSIXPath
	set {theResult, theValue, theError} to theURL's getResourceValue:(reference) forKey:(current application's NSURLTagNamesKey) |error|:(reference)
	if theResult as boolean is false then
		error (theError's localizedDescription() as text)
	else
		set theValue to theValue as list
		if theValue = {missing value} then set theValue to {}
		return theValue
	end if
end tagsForFile

on typeIDForFile(thisFileReference)
	set POSIXPath to getPOSIXPathForItem(thisFileReference)
	set theURL to current application's class "NSURL"'s fileURLWithPath:POSIXPath
	set listOfKeys to {current application's NSURLTypeIdentifierKey}
	set {theDict, theError} to theURL's resourceValuesForKeys:listOfKeys |error|:(reference)
	if theDict is missing value then
		error (theError's localizedDescription() as text)
	else
		set theResult to |NSURLTypeIdentifierKey| of (theDict as record)
	end if
end typeIDForFile

on generateNameWithAppendedDateTime(baseName)
	set localizedWordForAt to getLocalizedStringForKey("LOCALIZED_WORD_FOR_AT")
	-- GET THE CURRENT DATE
	set targetDate to current application's NSDate's |date|()
	-- CREATE A NEW DATE FORMATTER
	set dateFormatter to current application's NSDateFormatter's alloc()'s init()
	-- SET FORMTTER TO DATE STRING FORMAT
	dateFormatter's setDateFormat:"yyyy-MM-dd"
	-- GENERATE THE DATE STRING
	set currentDateString to (dateFormatter's stringFromDate:targetDate) as text
	--> "2015-07-15"
	-- SET FORMATTER TO TIME STRING FORMAT
	dateFormatter's setDateFormat:"HH.mm.ss a"
	-- GENERATE THE TIME STRING
	set currentTimeString to (dateFormatter's stringFromDate:targetDate) as text
	--> "18:18:32 PM"
	set nameDateString to baseName & space & currentDateString & space & localizedWordForAt & space & currentTimeString
	return nameDateString
end generateNameWithAppendedDateTime

(* FILE MANAGEMENT *)

on revealInFinder(theseItems)
	-- convert passed file refs to POSIX paths and then to file URLs
	if the class of theseItems is not list then set theseItems to theseItems as list
	set theseURLs to {}
	repeat with i from 1 to the count of theseItems
		set thisItem to item i of theseItems
		set thisItemPOSIXPath to my getPOSIXPathForItem(thisItem)
		set the end of theseURLs to (current application's NSURL's fileURLWithPath:thisItemPOSIXPath)
	end repeat
	-- reveal items in file viewer
	tell current application's NSWorkspace to set theWorkspace to sharedWorkspace()
	tell theWorkspace to activateFileViewerSelectingURLs:theseURLs
end revealInFinder

on listFolder(thisFolderReference)
	set POSIXPath to getPOSIXPathForItem(thisFolderReference)
	set thisURL to current application's NSURL's fileURLWithPath:POSIXPath
	set theFiles to {}
	set fileManager to current application's NSFileManager's defaultManager()
	set theFiles to fileManager's contentsOfDirectoryAtURL:thisURL includingPropertiesForKeys:{} options:(current application's NSDirectoryEnumerationSkipsHiddenFiles) |error|:(missing value)
	return theFiles as list
end listFolder

on deleteItem(thisItemReference)
	set POSIXPath to getPOSIXPathForItem(thisItemReference)
	set fileManager to current application's NSFileManager's defaultManager()
	set theResult to fileManager's removeItemAtPath:POSIXPath |error|:(missing value)
	return (theResult as boolean)
end deleteItem

on copyFileToFolder(thisFileReference, thisFolderReference)
	set POSIXPath to getPOSIXPathForItem(thisFileReference)
	set POSIXPath to current application's NSString's stringWithString:POSIXPath
	set folderPOSIXPath to getPOSIXPathForItem(thisFolderReference)
	set folderPOSIXPath to current application's NSString's stringWithString:folderPOSIXPath
	-- build path for new file
	set theName to POSIXPath's lastPathComponent()
	set newPath to folderPOSIXPath's stringByAppendingPathComponent:theName
	set fileManager to current application's NSFileManager's defaultManager()
	set {theResult, theError} to fileManager's copyItemAtPath:POSIXPath toPath:newPath |error|:(reference)
	if (theResult as boolean) is false then
		error (theError's localizedDescription() as text)
	else
		return newPath as string
	end if
end copyFileToFolder

on removeFileExtension(thisString)
	set aString to current application's NSString's stringWithString:thisString
	return (aString's stringByDeletingPathExtension()) as text
end removeFileExtension

on renameFile(thisFileReference, newName)
	set POSIXPath to getPOSIXPathForItem(thisFileReference)
	set fileManager to current application's NSFileManager's defaultManager()
	set POSIXPath to current application's NSString's stringWithString:POSIXPath
	set theNewPath to POSIXPath's stringByDeletingLastPathComponent()'s stringByAppendingPathComponent:newName
	if fileManager's fileExistsAtPath:theNewPath then
		error "A file with that name already exists"
	else
		set {theResult, theError} to fileManager's moveItemAtPath:POSIXPath toPath:theNewPath |error|:(reference)
		if (theResult as boolean) is false then
			error (theError's localizedDescription() as text)
		else
			return (theNewPath as string)
		end if
	end if
end renameFile

on sortedListOfItemsIn(folderPOSIXPath, sortKeyIndicator)
	set theNSURL to current application's class "NSURL"'s fileURLWithPath:folderPOSIXPath -- make URL for folder because that's what's needed
	set theNSFileManager to current application's NSFileManager's defaultManager() -- get file manager
	-- get contents of the folder
	set keysToRequest to {current application's NSURLPathKey, current application's NSURLContentModificationDateKey} -- keys for values we want for each item
	set theURLs to theNSFileManager's contentsOfDirectoryAtURL:theNSURL includingPropertiesForKeys:keysToRequest options:(current application's NSDirectoryEnumerationSkipsHiddenFiles) |error|:(missing value)
	-- get mod dates and paths for URLs
	set theInfoNSMutableArray to current application's NSMutableArray's array() -- array to store new values in
	repeat with i from 1 to theURLs's |count|()
		set anNSURL to (theURLs's objectAtIndex:(i - 1)) -- zero-based
		(theInfoNSMutableArray's addObject:(anNSURL's resourceValuesForKeys:keysToRequest |error|:(missing value))) -- get values dictionary and add to array
	end repeat
	if sortKeyIndicator is 0 then
		-- sort in name order
		set theNSSortDescriptor to current application's NSSortDescriptor's sortDescriptorWithKey:(current application's NSURLLocalizedNameKey) ascending:false -- describes the sort to perform
	else
		-- sort them in date order
		set theNSSortDescriptor to current application's NSSortDescriptor's sortDescriptorWithKey:(current application's NSURLContentModificationDateKey) ascending:false -- describes the sort to perform
	end if
	theInfoNSMutableArray's sortUsingDescriptors:{theNSSortDescriptor} -- do the sort
	-- get the path of the first item
	set thesePaths to (theInfoNSMutableArray's valueForKey:(current application's NSURLPathKey)) as list -- extract paths
	set theseAliasReferences to {}
	repeat with i from 1 to the count of thesePaths
		set the end of theseAliasReferences to ((item i of thesePaths) as POSIX file as alias)
	end repeat
	return theseAliasReferences
end sortedListOfItemsIn

on namesOfFolderItems(targetFolder) -- expects alias or POSIX path
	if class of targetFolder is alias then
		considering numeric strings
			if AppleScript's version ≥ "2.5" then
				set theURL to targetFolder
			else
				set theURL to current application's class "NSURL"'s fileURLWithPath:(POSIX path of targetFolder)
			end if
		end considering
	else
		set theURL to current application's class "NSURL"'s fileURLWithPath:targetFolder
	end if
	set fileManager to current application's NSFileManager's defaultManager()
	set allURLs to fileManager's contentsOfDirectoryAtURL:theURL includingPropertiesForKeys:{} options:(current application's NSDirectoryEnumerationSkipsHiddenFiles) |error|:(missing value)
	set theNames to (allURLs's valueForKey:"lastPathComponent") as list
	return theNames
end namesOfFolderItems

on checkForItemExistence(POSIXPathToItem)
	-- create an instance of the File Manager
	set thisFileManager to current application's NSFileManager's defaultManager()
	-- check for existence
	set fileExistenceStatus to (thisFileManager's fileExistsAtPath:POSIXPathToItem) as boolean
	-- return result
	return fileExistenceStatus
end checkForItemExistence

on openFolder(thisItem)
	set aPath to getPOSIXPathForItem(thisItem)
	set aURL to current application's class "NSURL"'s fileURLWithPath:aPath
	set aWorkspace to current application's NSWorkspace's sharedWorkspace
	aWorkspace's openURL:aURL
end openFolder

-- Creates a new folder. There is no error if the folder already exists, and it will also create intermediate folders if required
on createFolderNamedInFolder(proposedName, folderOrPath)
	set theFolderURL to my makeURLFromFileOrPath:folderOrPath
	if class of proposedName is text then set proposedName to current application's NSString's stringWithString:proposedName
	set proposedName to proposedName's stringByReplacingOccurrencesOfString:"/" withString:":"
	set theDestURL to theFolderURL's URLByAppendingPathComponent:proposedName
	set theFileManager to current application's NSFileManager's |defaultManager|()
	set {theResult, theError} to theFileManager's createDirectoryAtURL:theDestURL withIntermediateDirectories:true attributes:(missing value) |error|:(reference)
	if not (theResult as boolean) then error (theError's |localizedDescription|() as text)
end createFolderNamedInFolder

on createFolder(folderOrPath)
	set theFolderURL to my makeURLFromFileOrPath:folderOrPath
	set theFileManager to current application's NSFileManager's |defaultManager|()
	set {theResult, theError} to theFileManager's createDirectoryAtURL:theFolderURL withIntermediateDirectories:true attributes:(missing value) |error|:(reference)
	if not (theResult as boolean) then error (theError's |localizedDescription|() as text)
end createFolder

on pathToParentFolder(thisItem)
	set thisPath to getPOSIXPathForItem(thisItem)
	set aPath to current application's NSString's stringWithString:thisPath
	set parentFolderPath to aPath's stringByDeletingLastPathComponent
	return (parentFolderPath as text) & "/"
end pathToParentFolder


(* PATH HANDLERS *)

on appendToBaseFileNameInPath(thisItemReference, stringToAdd)
	set thePath to getPOSIXPathForItem(thisItemReference)
	set pathString to current application's NSString's stringWithString:thePath
	set theExtension to pathString's pathExtension()
	set thePathNoExt to pathString's stringByDeletingPathExtension()
	set newPath to (thePathNoExt's stringByAppendingString:stringToAdd)'s stringByAppendingPathExtension:theExtension
	return newPath as string
end appendToBaseFileNameInPath

on getPOSIXPathForItem(thisItemReference)
	(* This routine attempts to return a clean full POSIX path reference *)
	-- check class of input
	if the class of thisItemReference is alias then
		set thisItemReference to the POSIX path of thisItemReference
	else if the class of thisItemReference is «class furl» then
		set thisItemReference to the POSIX path of thisItemReference
	else if class of thisItemReference is string or class of thisItemReference is text then
		if thisItemReference begins with "'" and thisItemReference ends with "'" then
			-- remove single quotes
			set thisItemReference to text 2 thru -2 of thisItemReference
		end if
		if thisItemReference begins with "~" then
			set thisCocoaString to current application's NSString's stringWithString:thisItemReference
			set thisItemReference to (thisCocoaString's stringByExpandingTildeInPath()) as string
		end if
	end if
	return thisItemReference
end getPOSIXPathForItem

(* REMOVABLE DEVICES *)

on getRemovableDevicePaths()
	set optionsArray to current application's class "NSArray"'s arrayWithObjects:{current application's NSURLVolumeNameKey, current application's NSURLVolumeIsRemovableKey}
	set aFileManager to current application's class "NSFileManager"'s defaultManager
	set deviceURLs to aFileManager's mountedVolumeURLsIncludingResourceValuesForKeys:optionsArray options:0
	set deviceURLCount to the count of deviceURLs
	set matchingDevicePaths to {}
	repeat with i from 1 to deviceURLCount
		set thisDeviceURL to item i of deviceURLs
		set {theResult, theValue, theError} to (thisDeviceURL's getResourceValue:(reference) forKey:(current application's NSURLVolumeIsRemovableKey) |error|:(reference))
		if theResult is false then
			set errorDsc to (theError's localizedDescription() as text)
			log errorDsc
		else
			if (theValue as boolean) is true then
				set devicePath to (thisDeviceURL's |path|()) as string
				set {theResult, theValue, theError} to (thisDeviceURL's getResourceValue:(reference) forKey:(current application's NSURLVolumeNameKey) |error|:(reference))
				set volumeName to theValue as string
				set the end of matchingDevicePaths to devicePath
			end if
		end if
	end repeat
	return matchingDevicePaths
end getRemovableDevicePaths

on unmountSingleRemovableMediaDevice()
	set mountedRemovableMediaItems to getRemovableDevicePaths()
	set mountedMediaCount to (count of mountedRemovableMediaItems)
	if mountedMediaCount is 0 then
		say getLocalizedStringForKey("NO_MEDIA_TO_UNMOUNT")
	else if mountedMediaCount is 1 then
		set aSharedWorkspace to current application's class "NSWorkspace"'s sharedWorkspace
		set thisItem to item 1 of mountedRemovableMediaItems
		-- set aResult to aSharedWorkspace's unmountAndEjectDeviceAtPath:thisItem
		set theURL to current application's class "NSURL"'s fileURLWithPath:thisItem
		set {aResultBoolean, theError} to aSharedWorkspace's unmountAndEjectDeviceAtURL:theURL |error|:(reference)
		if aResultBoolean is false then
			set errorMsg to getLocalizedStringForKey("UNMOUNT_PROBLEM")
			set errorDsc to (theError's localizedDescription() as text)
			set errorKey to errorMsg & space & errorDsc
			displaySpokenErrorAlert(errorKey, "")
		else
			announceCompletion()
		end if
	else
		set mediaPaths to mountedRemovableMediaItems as list
		set dialogPrompt to getLocalizedStringForKey("CHOOSE_FROM_MOUNTED_MEDIAS_DIALOG_PROMPT")
		set spokenPrompt to getLocalizedStringForKey("CHOOSE_FROM_MOUNTED_MEDIAS_SPOKEN_PROMPT")
		say spokenPrompt without waiting until completion
		set chosenDevicePath to (choose from list mediaPaths with prompt dialogPrompt)
		if chosenDevicePath is false then error number -128
		set chosenDevicePath to chosenDevicePath as string
		set theURL to current application's class "NSURL"'s fileURLWithPath:chosenDevicePath
		set aSharedWorkspace to current application's class "NSWorkspace"'s sharedWorkspace
		set {aResultBoolean, theError} to aSharedWorkspace's unmountAndEjectDeviceAtURL:theURL |error|:(reference)
		if aResultBoolean is false then
			set errorMsg to getLocalizedStringForKey("UNMOUNT_PROBLEM")
			set errorDsc to (theError's localizedDescription() as text)
			set errorKey to errorMsg & space & errorDsc
			displaySpokenErrorAlert(errorKey, "")
		else
			announceCompletion()
		end if
	end if
end unmountSingleRemovableMediaDevice

on unmountRemovableMediaDeviceAtVolumePath(volumePath, shouldAnnounceCompletion)
	set mountedRemovableMediaItems to getRemovableDevicePaths()
	if volumePath is in mountedRemovableMediaItems then
		set volumePath to (current application's class "NSString"'s stringWithString:volumePath)
		set volumeName to volumePath's lastPathComponent
		set dismountPrefix to getLocalizedStringForKey("DISMOUNT_PREFIX")
		say dismountPrefix & (volumeName as text)
		set theURL to current application's class "NSURL"'s fileURLWithPath:volumePath
		set aSharedWorkspace to current application's class "NSWorkspace"'s sharedWorkspace
		set {aResultBoolean, theError} to aSharedWorkspace's unmountAndEjectDeviceAtURL:theURL |error|:(reference)
		if aResultBoolean is false then
			set errorMsg to getLocalizedStringForKey("UNMOUNT_PROBLEM")
			set errorDsc to (theError's localizedDescription() as text)
			set errorKey to errorMsg & space & errorDsc
			displaySpokenErrorAlert(errorKey, "")
		else
			if shouldAnnounceCompletion is true then announceCompletion()
		end if
	else
		displaySpokenErrorAlert("DEVICE_NOT_MOUNTED", "")
	end if
end unmountRemovableMediaDeviceAtVolumePath

on unmountAllRemovableMediaDevices()
	set dismountPrefix to getLocalizedStringForKey("DISMOUNT_PREFIX")
	set mountedRemovableMediaItems to getRemovableDevicePaths()
	repeat with i from 1 to the count of mountedRemovableMediaItems
		set volumePath to item i of mountedRemovableMediaItems
		set volumePath to (current application's class "NSString"'s stringWithString:volumePath)
		set volumeName to volumePath's lastPathComponent
		say dismountPrefix & (volumeName as text)
		unmountRemovableMediaDeviceAtVolumePath(volumePath, false)
	end repeat
	announceCompletion()
end unmountAllRemovableMediaDevices

on getPathForSingleRemovableMediaDevice()
	log "pathForSingleRemovableMediaDevice"
	set mountedRemovableMediaItems to getRemovableDevicePaths()
	set mountedMediaCount to (count of mountedRemovableMediaItems)
	if mountedMediaCount is 0 then
		displaySpokenErrorAlert("NO_REMOVABLE_MEDIA_DEVICE", "")
		error number -128
	else if mountedMediaCount is 1 then
		set thisItem to item 1 of mountedRemovableMediaItems
		return (thisItem as text)
	else
		set frontmostApp to aSharedWorkspace's frontmostApplication
		set appID to (frontmostApp's bundleIdentifier) as text
		set mediaPaths to mountedRemovableMediaItems as list
		set dialogPrompt to getLocalizedStringForKey("CHOOSE_FROM_MOUNTED_MEDIAS_DIALOG_PROMPT")
		set spokenPrompt to getLocalizedStringForKey("CHOOSE_FROM_MOUNTED_MEDIAS_SPOKEN_PROMPT")
		say spokenPrompt without waiting until completion
		tell application id appID
			activate
			set chosenDevicePath to (choose from list mediaPaths with prompt dialogPrompt)
		end tell
		if chosenDevicePath is false then error number -128
		set chosenDevicePath to chosenDevicePath as string
		return chosenDevicePath
	end if
end getPathForSingleRemovableMediaDevice

(* DERIVING PATHS *)

on derivePathForDocumentInDocumentsFolder(documentTitleToUse, documentExtensionToUse)
	set targetFolderPath to getPathForUserDocumentsDirectory(false) -- the POSIX path of (path to documents folder)
	if targetFolderPath does not end with "/" then set targetFolderPath to targetFolderPath & "/"
	set documentBaseNamePath to targetFolderPath & documentTitleToUse
	set documentFullPath to documentBaseNamePath & "." & documentExtensionToUse
	set aFileManager to current application's NSFileManager's defaultManager()
	set incrementIndex to 0
	repeat while (aFileManager's fileExistsAtPath:documentFullPath)
		set incrementIndex to incrementIndex + 1
		set documentFullPath to documentBaseNamePath & "-" & incrementIndex & "." & documentExtensionToUse
	end repeat
	return documentFullPath
end derivePathForDocumentInDocumentsFolder

on derivePathForDocumentInMoviesFolder(documentTitleToUse, documentExtensionToUse)
	set targetFolderPath to getPathForUserMoviesDirectory(false) --the POSIX path of (path to movies folder)
	if targetFolderPath does not end with "/" then set targetFolderPath to targetFolderPath & "/"
	set documentBaseNamePath to targetFolderPath & documentTitleToUse
	set documentFullPath to documentBaseNamePath & "." & documentExtensionToUse
	set aFileManager to current application's NSFileManager's defaultManager()
	set incrementIndex to 0
	repeat while (aFileManager's fileExistsAtPath:documentFullPath)
		set incrementIndex to incrementIndex + 1
		set documentFullPath to documentBaseNamePath & "-" & incrementIndex & "." & documentExtensionToUse
	end repeat
	return documentFullPath
end derivePathForDocumentInMoviesFolder

on derivePathForDocumentInPicturesFolder(documentTitleToUse, documentExtensionToUse)
	set targetFolderPath to getPathForUserPicturesDirectory(false) -- the POSIX path of (path to pictures folder)
	if targetFolderPath does not end with "/" then set targetFolderPath to targetFolderPath & "/"
	set documentBaseNamePath to targetFolderPath & documentTitleToUse
	set documentFullPath to documentBaseNamePath & "." & documentExtensionToUse
	set aFileManager to current application's NSFileManager's defaultManager()
	set incrementIndex to 0
	repeat while (aFileManager's fileExistsAtPath:documentFullPath)
		set incrementIndex to incrementIndex + 1
		set documentFullPath to documentBaseNamePath & "-" & incrementIndex & "." & documentExtensionToUse
	end repeat
	return documentFullPath
end derivePathForDocumentInPicturesFolder

on derivePathForDocumentInSpecifiedFolder(targetDirectory, documentTitleToUse, documentExtensionToUse)
	set targetFolderPath to the POSIX path of targetDirectory
	if targetFolderPath does not end with "/" then set targetFolderPath to targetFolderPath & "/"
	set documentBaseNamePath to targetFolderPath & documentTitleToUse
	set documentFullPath to documentBaseNamePath & "." & documentExtensionToUse
	set aFileManager to current application's NSFileManager's defaultManager()
	set incrementIndex to 0
	repeat while (aFileManager's fileExistsAtPath:documentFullPath)
		set incrementIndex to incrementIndex + 1
		set documentFullPath to documentBaseNamePath & "-" & incrementIndex & "." & documentExtensionToUse
	end repeat
	return documentFullPath
end derivePathForDocumentInSpecifiedFolder

(* CLIPBOARD HANDLERS *)

-- clipboard routines from Shane Stanley's Everyday AppleScriptObjC
-- https://macosxautomation.com/applescript/apps/
on fetchStorableClipboard()
	set aMutableArray to current application's NSMutableArray's array() -- used to store contents -- get the pasteboard and then its pasteboard items
	set thePasteboard to current application's NSPasteboard's generalPasteboard()
	set theItems to thePasteboard's pasteboardItems()
	-- loop through pasteboard items
	repeat with i from 1 to count of theItems
		-- make a new pasteboard item to store existing item's stuff
		set newPBItem to current application's NSPasteboardItem's alloc()'s init()
		-- get the types of data stored on the pasteboard item
		set theTypes to (item i of theItems)'s types()
		-- for each type, get the corresponding data and store it all in the new pasteboard item 
		repeat with j from 1 to count of theTypes
			set theData to ((item i of theItems)'s dataForType:(item j of theTypes))'s mutableCopy() -- mutableCopy makes deep copy
			if theData is not missing value then
				(newPBItem's setData:theData forType:(item j of theTypes))
			end if
		end repeat
		-- add new pasteboard item to array
		(aMutableArray's addObject:newPBItem)
	end repeat
	return aMutableArray
end fetchStorableClipboard

on restoreClipboard:theArray -- get pasteboard
	set thePasteboard to current application's NSPasteboard's generalPasteboard() -- clear it, then write new contents
	thePasteboard's clearContents()
	thePasteboard's writeObjects:theArray
end restoreClipboard:

on writeTextToClipboard:someText
	my restoreClipboard:{someText}
end writeTextToClipboard:

on speakTheClipboardString()
	if (clipboard info for «class utf8») is not {} then
		my speakWithMutedInput(get the clipboard as «class utf8»)
	else
		my speakWithMutedInput("NO_TEXT_ON_CLIPBOARD")
	end if
	-- store the JXA call to this handler
	set JXACommandString to "Library('DC-Workspace').speakTheClipboardString();"
	tell script "DC-Support" to storeJXACommandString(JXACommandString)
end speakTheClipboardString

on extractClipboardContent(skipRTF)
	set clipboardInfo to run script "clipboard info for «class weba»"
	if clipboardInfo is not {} then
		return {«class weba», "webarchive", (get the clipboard as «class weba»)}
	end if
	set clipboardInfo to run script "clipboard info for «class PNGf»"
	if clipboardInfo is not {} then
		return {«class PNGf», "png", (get the clipboard as «class PNGf»)}
	end if
	if skipRTF is false then
		set clipboardInfo to run script "clipboard info for «class RTF »"
		if clipboardInfo is not {} then
			return {«class RTF », "rtf", (get the clipboard as «class RTF »)}
		end if
	end if
	set clipboardInfo to run script "clipboard info for Unicode text"
	if clipboardInfo is not {} then
		return {Unicode text, "txt", (get the clipboard as Unicode text)}
	end if
	return false
end extractClipboardContent

on writeClipboardToStandardFile(revealInFinder)
	try
		set thePasteboard to current application's NSPasteboard's generalPasteboard()
		set theItems to thePasteboard's pasteboardItems()
		if theItems as list is {} then error "NO_CLIPBOARD_CONTENTS"
		repeat with i from 1 to count of theItems
			set theTypes to (item i of theItems)'s types()
			repeat with j from 1 to count of theTypes
				set thisType to (item j of theTypes) as text
				if thisType is "com.apple.webarchive" then
					set defaultName to my getLocalizedStringForKey("TRANSLATION_CLIPBOARD_WEBARCHIVE")
					set theData to ((item i of theItems)'s dataForType:(item j of theTypes))'s mutableCopy() -- mutableCopy makes deep copy
					set targetFilePath to my derivePathForDocumentInDocumentsFolder(defaultName, "webarchive")
					set theResult to (theData's writeToFile:targetFilePath atomically:true |error|:(missing value))
					if revealInFinder is true then
						my revealInFinder({targetFilePath})
					end if
					my announceCompletion()
					return {"com.apple.webarchive", targetFilePath}
				else if thisType is "public.png" then
					set defaultName to my getLocalizedStringForKey("TRANSLATION_CLIPBOARD_IMAGE")
					set theData to ((item i of theItems)'s dataForType:(item j of theTypes))'s mutableCopy() -- mutableCopy makes deep copy
					set targetFilePath to my derivePathForDocumentInPicturesFolder(defaultName, "png")
					set theResult to (theData's writeToFile:targetFilePath atomically:true |error|:(missing value))
					if revealInFinder is true then
						my revealInFinder({targetFilePath})
					end if
					my announceCompletion()
					return {"public.png", targetFilePath}
				else if thisType is "public.rtf" then
					set defaultName to my getLocalizedStringForKey("TRANSLATION_CLIPBOARD_TEXT")
					set theData to ((item i of theItems)'s dataForType:(item j of theTypes))'s mutableCopy() -- mutableCopy makes deep copy
					set theString to (current application's NSString's alloc's initWithData:theData encoding:(current application's NSUTF8StringEncoding))
					set targetFilePath to my derivePathForDocumentInDocumentsFolder(defaultName, "rtf")
					set theResult to (theString's writeToFile:targetFilePath atomically:true encoding:(current application's NSUTF8StringEncoding) |error|:(missing value))
					if revealInFinder is true then
						my revealInFinder({targetFilePath})
					end if
					my announceCompletion()
					return {"public.rtf", targetFilePath}
				else if thisType is "public.utf8-plain-text" then
					set defaultName to my getLocalizedStringForKey("TRANSLATION_CLIPBOARD_TEXT")
					set theData to ((item i of theItems)'s dataForType:(item j of theTypes))'s mutableCopy() -- mutableCopy makes deep copy
					set theString to (current application's NSString's alloc's initWithData:theData encoding:(current application's NSUTF8StringEncoding))
					set targetFilePath to my derivePathForDocumentInDocumentsFolder(defaultName, "txt")
					set theResult to (theString's writeToFile:targetFilePath atomically:true encoding:(current application's NSUTF8StringEncoding) |error|:(missing value))
					if revealInFinder is true then
						my revealInFinder({targetFilePath})
					end if
					my announceCompletion()
					return {"public.utf8-plain-text", targetFilePath}
				end if
			end repeat
		end repeat
		error "NO_CLIPBOARD_CONTENTS"
	on error errorMessage number errorNumber
		if errorNumber is not -128 then
			my displaySpokenErrorAlert(errorMessage, "")
		end if
		error number -128
	end try
end writeClipboardToStandardFile

on newMailMessageWithContentsOfClipboard(useTextInsteadOfRTF)
	try
		set thePasteboard to current application's NSPasteboard's generalPasteboard()
		set theItems to thePasteboard's pasteboardItems()
		if theItems as list is {} then error "NO_CLIPBOARD_CONTENTS"
		repeat with i from 1 to count of theItems
			set theTypes to (item i of theItems)'s types()
			repeat with j from 1 to count of theTypes
				set thisType to (item j of theTypes) as text
				if thisType is "com.apple.webarchive" then
					set defaultName to my getLocalizedStringForKey("TRANSLATION_CLIPBOARD_WEBARCHIVE")
					set theData to ((item i of theItems)'s dataForType:(item j of theTypes))'s mutableCopy() -- mutableCopy makes deep copy
					set targetFilePath to my derivePathForDocumentInDocumentsFolder(defaultName, "webarchive")
					set theResult to (theData's writeToFile:targetFilePath atomically:true |error|:(missing value))
					tell script "DC-Mail"
						set aMessage to createNewOutgoingMailMessage("", "", {(targetFilePath as POSIX file)}, true)
						return aMessage
					end tell
				else if thisType is "public.png" then
					set defaultName to my getLocalizedStringForKey("TRANSLATION_CLIPBOARD_IMAGE")
					set theData to ((item i of theItems)'s dataForType:(item j of theTypes))'s mutableCopy() -- mutableCopy makes deep copy
					set targetFilePath to my derivePathForDocumentInPicturesFolder(defaultName, "png")
					set theResult to (theData's writeToFile:targetFilePath atomically:true |error|:(missing value))
					tell script "DC-Mail"
						set aMessage to createNewOutgoingMailMessage("", "", {(targetFilePath as POSIX file)}, true)
						return aMessage
					end tell
				else if thisType is "public.rtf" and (useTextInsteadOfRTF is false) then
					set defaultName to my getLocalizedStringForKey("TRANSLATION_CLIPBOARD_TEXT")
					set theData to ((item i of theItems)'s dataForType:(item j of theTypes))'s mutableCopy() -- mutableCopy makes deep copy
					set theString to (current application's NSString's alloc's initWithData:theData encoding:(current application's NSUTF8StringEncoding))
					set targetFilePath to my derivePathForDocumentInDocumentsFolder(defaultName, "rtf")
					set theResult to (theString's writeToFile:targetFilePath atomically:true encoding:(current application's NSUTF8StringEncoding) |error|:(missing value))
					tell script "DC-Mail"
						set aMessage to createNewOutgoingMailMessage("", "", {(targetFilePath as POSIX file)}, true)
						return aMessage
					end tell
				else if thisType is "public.utf8-plain-text" then
					set defaultName to my getLocalizedStringForKey("TRANSLATION_CLIPBOARD_TEXT")
					set theData to ((item i of theItems)'s dataForType:(item j of theTypes))'s mutableCopy() -- mutableCopy makes deep copy
					set theString to (current application's NSString's alloc's initWithData:theData encoding:(current application's NSUTF8StringEncoding))
					(*
					set targetFilePath to my derivePathForDocumentInDocumentsFolder(defaultName, "txt")
					set theResult to (theString's writeToFile:targetFilePath atomically:true encoding:(current application's NSUTF8StringEncoding) |error|:(missing value))
					tell script "DC-Mail"
						set aMessage to createNewOutgoingMailMessage("", "", {(targetFilePath as POSIX file)}, true)
						return aMessage
					end tell
					*)
					-- use plain text as the content of the message instead of as an attachment
					tell script "DC-Mail"
						set aMessage to createNewOutgoingMailMessage("", (theString as text), {}, true)
						return aMessage
					end tell
				end if
			end repeat
		end repeat
		error "NO_CLIPBOARD_CONTENTS"
	on error errorMessage number errorNumber
		if errorNumber is not -128 then
			my displaySpokenErrorAlert(errorMessage, "")
		end if
		error number -128
	end try
end newMailMessageWithContentsOfClipboard

on newPagesDocumentWithClipboardString()
	if (clipboard info for «class utf8») is not {} then
		tell script "DC-Pages"
			createNewPagesWordProcessingDocument((get the clipboard as «class utf8»), true)
		end tell
	else
		my speakWithMutedInput("NO_TEXT_ON_CLIPBOARD")
	end if
end newPagesDocumentWithClipboardString

(* PDF *)

on beginPDFMergeOfFinderSelection()
	try
		tell application id "com.apple.finder"
			set selectedItems to (get selection as alias list)
		end tell
		if selectedItems is {} then error "NO_FINDER_SELECTION"
		repeat with i from 1 to the count of selectedItems
			set thisItem to item i of selectedItems
			tell script "DC-Workspace"
				set thisTypeID to typeIDForFile(thisItem)
			end tell
			if thisTypeID is not in {"com.adobe.pdf"} then
				error "NOT_PDF_FILE"
			end if
		end repeat
		set libraryPath to the POSIX path of (path to me)
		set workflowFilePath to libraryPath & "Contents/Resources/combine-pdf.workflow"
		say (getLocalizedStringForKey("BEGINNING_PDF_MERGE"))
		--runWorkflowAtPath(workflowFilePath)
		do shell script "automator " & (quoted form of workflowFilePath)
	on error errorMessage number errorNumber
		my logThis(errorMessage)
		if errorNumber is not -128 and errorMessage is not missing value then
			my displaySpokenErrorAlert(errorMessage, "")
		end if
		error number -128
	end try
end beginPDFMergeOfFinderSelection

on completePDFMergeOfFinderSelection(mergedPDFFile)
	try
		if class of mergedPDFFile is list then
			set mergedPDFFile to item 1 of mergedPDFFile
		end if
		set voicePrompt to (getLocalizedStringForKey("SPOKEN_PROMPT_FOR_PDF_MERGE"))
		set dialogPrompt to (getLocalizedStringForKey("DIALOG_PROMPT_FOR_PDF_MERGE"))
		
		say voicePrompt without waiting until completion
		tell application id "com.apple.finder"
			activate
			set chosenFileReference to (choose file name with prompt dialogPrompt default location (path to desktop folder))
		end tell
		
		set newItemPOSIXPath to the POSIX path of chosenFileReference
		if newItemPOSIXPath does not end with ".pdf" then
			set newItemPOSIXPath to newItemPOSIXPath & ".pdf"
		end if
		
		its moveItem:mergedPDFFile toMake:newItemPOSIXPath withReplacing:true
		
		delay 2
		
		revealInFinder(newItemPOSIXPath)
		
		announceCompletion()
	on error errorMessage number errorNumber
		my logThis(errorMessage)
		if errorNumber is not -128 then
			my displaySpokenErrorAlert(errorMessage, "")
		end if
		error number -128
	end try
end completePDFMergeOfFinderSelection

(*
on runWorkflowAtPath(workflowPath)
	set wPath to current application's NSString's stringWithString:workflowPath
	set wPath to (wPath's stringByExpandingTildeInPath()) as string
	set theURL to current application's NSURL's fileURLWithPath:wPath
	current application's AMWorkflow's runWorkflowAtURL:theURL withInput:(missing value) |error|:(missing value)
end runWorkflowAtPath
*)

on runWorkflowAtPath(workflowPath)
	set wPath to current application's NSString's stringWithString:workflowPath
	set wPath to (wPath's stringByExpandingTildeInPath()) as string
	set utilPath to "/usr/bin/automator"
	set theTask to current application's NSTask's launchedTaskWithLaunchPathArguments(utilPath, {wPath})
	theTask's waitUntilExit
	return true
end runWorkflowAtPath

(* IMAGE FILE METADATA *)

on getImageDimensions(thisImageFilePOSIXPath)
	try
		(* IMPORTANT: IMAGE FILE METADATA WILL BE UNAVAILABLE UNLESS THE ITEM IS FIRST IMPORTED INTO THE MD DATABASE *)
		do shell script "mdimport " & (quoted form of thisImageFilePOSIXPath)
		--set imageHeight to (do shell script "mdls -raw -name kMDItemPixelHeight" & space & quoted form of thisImageFilePOSIXPath)
		--set imageWidth to (do shell script "mdls -raw -name kMDItemPixelWidth" & space & quoted form of thisImageFilePOSIXPath)
		--set imageDimensionsData to {imageWidth, imageHeight}
		set imageDimensionsData to getkMDItemPixelWidthkMDItemPixelHeightFromImageFile(thisImageFilePOSIXPath)
		--if imageDimensionsData contains "(null)" then
		if imageDimensionsData is false then
			tell application "Image Events"
				launch
				try
					set thisImage to open thisImageFilePOSIXPath
					copy dimensions of thisImage to {imageWidth, imageHeight}
					close thisImage
				on error
					try
						close thisImage
					end try
					error "problem reading"
				end try
			end tell
			return {imageWidth, imageHeight}
		else
			return imageDimensionsData
		end if
	on error
		return false
	end try
end getImageDimensions

on extractkMDItemDescription(thisImageFile)
	-- uses Spotlight to retrieve embedded description metadata (if any)
	try
		set thisImagePOSIXPath to the POSIX path of thisImageFile
		do shell script "mdimport " & (quoted form of thisImagePOSIXPath)
		set the embeddedDescription to do shell script "mdls -raw -name kMDItemDescription " & (quoted form of thisImagePOSIXPath)
		if embeddedDescription is "(null)" then
			set embeddedDescription to ""
		end if
		return embeddedDescription
	on error
		return ""
	end try
end extractkMDItemDescription

on getkMDItemDescriptionFromImageFile(thisFile)
	set POSIXPath to POSIX path of thisFile
	set theURL to current application's class "NSURL"'s fileURLWithPath:POSIXPath
	set thisMetadataItem to current application's NSMetadataItem's alloc()'s initWithURL:theURL
	set theseMetadataTags to (thisMetadataItem's attributes) as list
	if theseMetadataTags contains "kMDItemDescription" then
		return (thisMetadataItem's valueForAttribute:"kMDItemDescription") as string
	else
		return ""
	end if
end getkMDItemDescriptionFromImageFile

on getkMDItemTitleFromImageFile(thisFile)
	set POSIXPath to POSIX path of thisFile
	set theURL to current application's class "NSURL"'s fileURLWithPath:POSIXPath
	set thisMetadataItem to current application's NSMetadataItem's alloc()'s initWithURL:theURL
	set theseMetadataTags to (thisMetadataItem's attributes) as list
	if theseMetadataTags contains "kMDItemTitle" then
		return (thisMetadataItem's valueForAttribute:"kMDItemTitle") as string
	else
		return ""
	end if
end getkMDItemTitleFromImageFile

on getkMDItemPixelWidthkMDItemPixelHeightFromImageFile(thisFile)
	set POSIXPath to POSIX path of thisFile
	set theURL to current application's class "NSURL"'s fileURLWithPath:POSIXPath
	set thisMetadataItem to current application's NSMetadataItem's alloc()'s initWithURL:theURL
	set theseMetadataTags to (thisMetadataItem's attributes) as list
	if theseMetadataTags contains "kMDItemPixelHeight" then
		set imageHeight to (thisMetadataItem's valueForAttribute:"kMDItemPixelHeight") as integer
		set imageWidth to (thisMetadataItem's valueForAttribute:"kMDItemPixelWidth") as integer
		return {imageWidth, imageHeight}
	else
		return false
	end if
end getkMDItemPixelWidthkMDItemPixelHeightFromImageFile


(* FINDER ITEM MOVE COPY *)

-- * Routines by Shane Stanley <http://macosxautomation.com/applescript/apps/Script_Libs.html>

-- * Copies a file or folder, replacing an existing file or folder if you wish. The destination must include the new file's name
on copyItem:aFileOrPath toMake:destFileOrPath withReplacing:replaceFlag
	set theSourceURL to my makeURLFromFileOrPath:aFileOrPath
	set theDestURL to my makeURLFromFileOrPath:destFileOrPath
	my copyFromURL:theSourceURL toURL:theDestURL withReplacing:replaceFlag
end copyItem:toMake:withReplacing:

-- * Moves a file or folder, replacing an existing file or folder if you wish. The destination must include the file's name, which does not have to match the original
on moveItem:aFileOrPath toMake:destFileOrPath withReplacing:replaceFlag
	set theSourceURL to my makeURLFromFileOrPath:aFileOrPath
	set theDestURL to my makeURLFromFileOrPath:destFileOrPath
	my moveFromURL:theSourceURL toURL:theDestURL withReplacing:replaceFlag
end moveItem:toMake:withReplacing:

-- * Moves a file or folder, replacing an existing file or folder if you wish. The destination is that of the destination folder; the original item's name will be used
on moveItem:aFileOrPath intoFolder:folderOrPath withReplacing:replaceFlag
	set theSourceURL to my makeURLFromFileOrPath:aFileOrPath
	set destName to theSourceURL's |lastPathComponent|()
	set theFolderURL to my makeURLFromFileOrPath:folderOrPath
	set theDestURL to theFolderURL's URLByAppendingPathComponent:destName
	my moveFromURL:theSourceURL toURL:theDestURL withReplacing:replaceFlag
end moveItem:intoFolder:withReplacing:

-- * Moves a file or folder to a folder. If an item of the same name already exists, it adds " copy" to the name before the extension, and if that name is taken it adds " copy-#", where # starts from 1 and increments until success
-- Returns the new POSIX path of the file
on moveItem:aFileOrPath uniquelyToFolder:folderOrPath
	set theSourceURL to my makeURLFromFileOrPath:aFileOrPath
	set destName to theSourceURL's |lastPathComponent|()
	set destNameLessExt to destName's |stringByDeletingPathExtension|()
	set theExtension to theSourceURL's |pathExtension|()
	set theFolderURL to my makeURLFromFileOrPath:folderOrPath
	set theDestURL to theFolderURL's URLByAppendingPathComponent:destName
	set theFileManager to current application's NSFileManager's |defaultManager|()
	set i to 0
	repeat
		set {theResult, theError} to (theFileManager's moveItemAtURL:theSourceURL toURL:theDestURL |error|:(reference))
		if theResult as boolean then exit repeat
		if (theError's code() as integer = current application's NSFileWriteFileExistsError as integer) then -- it already exists, so change name
			if i = 0 then
				set proposedName to (destNameLessExt's stringByAppendingString:copyString)'s stringByAppendingPathExtension:theExtension
			else
				set proposedName to (destNameLessExt's stringByAppendingString:(copyString & space & i))'s stringByAppendingPathExtension:theExtension
			end if
			set theDestURL to theFolderURL's URLByAppendingPathComponent:proposedName
			set i to i + 1
		else -- an error other than file already exists, so return error
			error (theError's |localizedDescription|() as text)
		end if
	end repeat
	return theDestURL's |path|() as text
end moveItem:uniquelyToFolder:

-- * This handler is called by other handlers, and is not meant to called directly
on moveFromURL:sourceURL toURL:destinationURL withReplacing:replaceFlag
	set theFileManager to current application's NSFileManager's |defaultManager|()
	set {theResult, theError} to (theFileManager's moveItemAtURL:sourceURL toURL:destinationURL |error|:(reference))
	if not theResult as boolean then
		if replaceFlag and (theError's code() = current application's NSFileWriteFileExistsError) then -- it already exists, so try replacing
			-- replace existing file with temp file atomically, then delete temp directory
			set {theResult, theError} to theFileManager's replaceItemAtURL:destinationURL withItemAtURL:sourceURL backupItemName:(missing value) options:(current application's NSFileManagerItemReplacementUsingNewMetadataOnly) resultingItemURL:(missing value) |error|:(reference)
			-- if replacement failed, return error
			if not theResult as boolean then error (theError's |localizedDescription|() as text)
		else -- replaceFlag is false or an error other than file already exists, so return error
			error (theError's |localizedDescription|() as text)
		end if
	end if
end moveFromURL:toURL:withReplacing:

-- * This handler is called by other handlers, and is not meant to called directly
on copyFromURL:sourceURL toURL:destinationURL withReplacing:replaceFlag
	set theFileManager to current application's NSFileManager's |defaultManager|()
	set {theResult, theError} to (theFileManager's copyItemAtURL:sourceURL toURL:destinationURL |error|:(reference))
	if not theResult as boolean then
		if replaceFlag and (theError's code() as integer = current application's NSFileWriteFileExistsError as integer) then -- it already exists, so try replacing
			-- create suitable temporary directory in destinationURL's parent folder
			set {tempFolderURL, theError} to theFileManager's URLForDirectory:(current application's NSItemReplacementDirectory) inDomain:(current application's NSUserDomainMask) appropriateForURL:(destinationURL's |URLByDeletingLastPathComponent|()) create:true |error|:(reference)
			if tempFolderURL = missing value then error (theError's |localizedDescription|() as text) -- failed, so return error
			-- copy sourceURL to temp directory
			set tempDestURL to tempFolderURL's URLByAppendingPathComponent:(destinationURL's |lastPathComponent|())
			set {theResult, theError} to theFileManager's copyItemAtURL:sourceURL toURL:tempDestURL |error|:(reference)
			if not theResult as boolean then
				-- copy failed, so delete temporary directory and return error
				theFileManager's removeItemAtURL:tempFolderURL |error|:(missing value)
				error (theError's |localizedDescription|() as text)
			end if
			-- replace existing file with temp file atomically, then delete temp directory
			set {theResult, theError} to theFileManager's replaceItemAtURL:destinationURL withItemAtURL:tempDestURL backupItemName:(missing value) options:(current application's NSFileManagerItemReplacementUsingNewMetadataOnly) resultingItemURL:(missing value) |error|:(reference)
			theFileManager's removeItemAtURL:tempFolderURL |error|:(missing value)
			-- if replacement failed, return error
			if not theResult as boolean then error (theError's |localizedDescription|() as text)
		else -- replaceFlag is false or an error other than file already exists, so return error
			error (theError's |localizedDescription|() as text)
		end if
	end if
end copyFromURL:toURL:withReplacing:

-- * This handler is called by other handlers
on makeURLFromFileOrPath:theFileOrPathInput
	-- make it into a Cocoa object for easier comparison
	set theFileOrPath to item 1 of (current application's NSArray's arrayWithObject:theFileOrPathInput)
	if (theFileOrPath's isKindOfClass:(current application's NSString)) as boolean then
		if (theFileOrPath's hasPrefix:"/") as boolean then -- full POSIX path
			return current application's class "NSURL"'s fileURLWithPath:theFileOrPath
		else if (theFileOrPath's hasPrefix:"~") as boolean then -- POSIX path needing ~ expansion
			return current application's class "NSURL"'s fileURLWithPath:(theFileOrPath's |stringByExpandingTildeInPath|())
		else -- must be HFS path
			return current application's class "NSURL"'s fileURLWithPath:(POSIX path of theFileOrPathInput)
		end if
	else if (theFileOrPath's isKindOfClass:(current application's class "NSURL")) as boolean then -- happens with files and aliases in 10.11
		return theFileOrPath
	else -- must be a file or alias
		return current application's class "NSURL"'s fileURLWithPath:(POSIX path of theFileOrPathInput)
	end if
end makeURLFromFileOrPath:

(* APP ANNOUNCER *)

on launchAppAnnouncer()
	set libraryPath to the POSIX path of (path to me)
	set appletPath to getPathToHelperApp("App Announcer.app")
	do shell script "open" & space & quoted form of appletPath
end launchAppAnnouncer

on stopAppAnnouncer()
	if running of application id "com.NyhthawkProductions.AppAnnouncer" is true then
		tell application id "com.NyhthawkProductions.AppAnnouncer" to quit
	end if
end stopAppAnnouncer

(* BIG HONKING TEXT *)

on showDateInfoOverlay()
	set dateInfo to date string of (get current date) as string
	stopShowingOverlay()
	showOverlayText(dateInfo)
end showDateInfoOverlay

on showComputerNameOverlay()
	set hostName to computer name of (get system info)
	stopShowingOverlay()
	showOverlayText(hostName)
end showComputerNameOverlay

on showHostNameOverlay()
	set hostName to host name of (get system info)
	stopShowingOverlay()
	showOverlayText(hostName)
end showHostNameOverlay

on showCurrentWifiNetworkName()
	try
		set resultData to (do shell script "/Sy*/L*/Priv*/Apple8*/V*/C*/R*/airport -I | grep ' SSID'")
		set resultData to trimWhiteSpaceAroundString(resultData)
	on error
		set resultData to "No WiFi Network"
	end try
	stopShowingOverlay()
	showOverlayText(resultData)
end showCurrentWifiNetworkName

on showScreenResolution()
	try
		set resultData to do shell script "system_profiler SPDisplaysDataType | grep 'Resolution: '"
		set resultData to trimWhiteSpaceAroundString(resultData)
	on error
		set resultData to "Not Available"
	end try
	stopShowingOverlay()
	showOverlayText(resultData)
end showScreenResolution

on showComputerSerialNumber()
	try
		set resultData to do shell script "system_profiler SPHardwareDataType | grep 'Serial Number'"
		set resultData to trimWhiteSpaceAroundString(resultData)
	on error
		set resultData to "Not Available"
	end try
	stopShowingOverlay()
	showOverlayText(resultData)
end showComputerSerialNumber

on showOverlayText(aString)
	set libraryPath to the POSIX path of (path to me)
	set helperAppletPath to getPathToHelperApp("Overlay Text Helper.app")
	ignoring application responses
		tell application helperAppletPath
			open aString
		end tell
	end ignoring
end showOverlayText

on stopShowingOverlay()
	tell application "System Events"
		set processNames to the name of every process
	end tell
	if processNames contains "BigHonkingText" then
		try
			do shell script "killall BigHonkingText"
		end try
		delay 1
	end if
end stopShowingOverlay

on trimWhiteSpaceAroundString(thisString)
	set theString to current application's NSString's stringWithString:thisString
	set theWhiteSet to current application's NSCharacterSet's whitespaceAndNewlineCharacterSet()
	set theString to theString's stringByTrimmingCharactersInSet:theWhiteSet
	return theString as text
end trimWhiteSpaceAroundString

(* HELPER APPS FOLDER *)
on getPathToHelperAppsFolder()
	set targetDirectory to getPathForUserApplicationsDirectory(false) & "/" & "Dictation Helper Apps/"
	if checkForItemExistence(targetDirectory) is true then
		return targetDirectory
	else
		my displaySpokenErrorAlert("NO_HELPER_APPS_FOLDER", "")
		error number -128
	end if
end getPathToHelperAppsFolder

on getPathToHelperApp(thisAppFileName)
	if thisAppFileName does not end with ".app" then
		set thisAppFileName to thisAppFileName & ".app"
	end if
	set helperAppsFolderPath to getPathToHelperAppsFolder()
	set targetAppPath to helperAppsFolderPath & "/" & thisAppFileName
	if checkForItemExistence(targetAppPath) is true then
		return targetAppPath
	else
		set baseErrorMsg to getLocalizedStringForKey("HELPER_APP_MISSING")
		set errorMsg to replaceStringInString(baseErrorMsg, "$@1", thisAppFileName)
		my displaySpokenErrorAlert(errorMsg, "")
		error number -128
	end if
end getPathToHelperApp

on replaceStringInString(sourceText, searchString, replacementString)
	set aString to current application's NSString's stringWithString:sourceText
	set resultString to the (aString's stringByReplacingOccurrencesOfString:searchString withString:replacementString)
	return resultString as text
end replaceStringInString

(* AIRPROP *)

on beginAirDropOfFinderSelection()
	try
		tell application id "com.apple.finder"
			set selectedItems to (get selection)
			if selectedItems is {} then error "NO_FINDER_SELECTION"
			set theseItems to {}
			repeat with i from 1 to the count of selectedItems
				set the end of theseItems to (item i of selectedItems) as alias
			end repeat
		end tell
		my beginAirDropSessionFor(theseItems)
	on error errorMessage number errorNumber
		my logThis(errorMessage)
		if errorNumber is not -128 then
			my displaySpokenErrorAlert(errorMessage, "")
		end if
		error number -128
	end try
end beginAirDropOfFinderSelection

on beginAirDropSessionFor(theseItems)
	set helperAppletPath to getPathToHelperApp("AirDrop Helper.app")
	ignoring application responses
		tell application helperAppletPath
			open theseItems
		end tell
	end ignoring
end beginAirDropSessionFor

on turnOnAirDrop(stayInFinder)
	set currentAppID to getIDOfFrontmostApplication()
	tell application "Finder"
		activate
		make new Finder window
	end tell
	tell application "System Events"
		tell process "Finder"
			click menu "Go" of menu bar 1
			delay 0.5
			click menu item "AirDrop" of menu "Go" of menu bar 1
		end tell
	end tell
	if stayInFinder is false then
		delay 1
		tell application id currentAppID
			activate
		end tell
	end if
end turnOnAirDrop


(* PICTURE TAKER *)

on takeVSnapshotAndAddToPhotos(shouldActivatePhotos, spokenPrompt)
	-- to have no spoken prompt, enter a null string as value (" ") for spokenPrompt
	-- to use the default spoken prompt, enter missing value as value for spokenPrompt
	set helperAppletPath to getPathToHelperApp("PictureTaker Helper.app")
	ignoring application responses
		tell application helperAppletPath
			takePictureAndAddToPhotos(shouldActivatePhotos, spokenPrompt)
		end tell
	end ignoring
end takeVSnapshotAndAddToPhotos

on takeVSnapshotAutomaticallyAndAddToPhotos(shouldActivatePhotos)
	try
		set libraryPath to the POSIX path of (path to me)
		set helperAppletPath to libraryPath & "Contents/Resources/PictureTaker Helper.app"
		tell application helperAppletPath
			set captureFilePath to takeVideoSnapshotAutomaticallyAndAddToPhotos(shouldActivatePhotos)
		end tell
		my logThis(captureFilePath)
		if running of application id "com.apple.PictureTaker-Helper" is true then
			tell application id "com.apple.PictureTaker-Helper" to quit
		end if
		return captureFilePath
	on error errorMessage
		return errorMessage -- false
	end try
end takeVSnapshotAutomaticallyAndAddToPhotos

on takeVSnapshotAutomatically()
	try
		set libraryPath to the POSIX path of (path to me)
		set helperAppletPath to libraryPath & "Contents/Resources/PictureTaker Helper.app"
		tell application helperAppletPath
			set captureFilePath to takeVideoSnapshotAutomatically()
		end tell
		my logThis(captureFilePath)
		if running of application id "com.apple.PictureTaker-Helper" is true then
			tell application id "com.apple.PictureTaker-Helper" to quit
		end if
		return captureFilePath
	on error
		return false
	end try
end takeVSnapshotAutomatically

on takeVSnapshot(shouldRevealInFinder, spokenPrompt)
	-- to have no spoken prompt, enter a null string as value (" ") for spokenPrompt
	-- to use the default spoken prompt, enter missing value as value for spokenPrompt
	try
		set libraryPath to the POSIX path of (path to me)
		set helperAppletPath to libraryPath & "Contents/Resources/PictureTaker Helper.app"
		tell application helperAppletPath
			set captureFilePath to takeVideoSnapshotToFile(shouldRevealInFinder, spokenPrompt)
		end tell
		my logThis(captureFilePath)
		if running of application id "com.apple.PictureTaker-Helper" is true then
			tell application id "com.apple.PictureTaker-Helper" to quit
		end if
		return captureFilePath
	on error
		return false
	end try
end takeVSnapshot

(* SCREEN SAVER *)

on beginCurrentScreenSaver()
	tell current application
		do shell script "open /System/Library/Frameworks/ScreenSaver.framework/Resources/ScreenSaverEngine.app"
	end tell
	-- store the JXA call to this handler
	set JXACommandString to "Library('DC-Workspace').beginCurrentScreenSaver();"
	tell script "DC-Support" to storeJXACommandString(JXACommandString)
end beginCurrentScreenSaver

(* VOLUME SETTINGS *)

on increaseOutputVolumeByDefaultIncrement()
	set currentVolumeSetting to getCurrentOutputVolume()
	set newVolumeSetting to currentVolumeSetting + defaultVolumeIncrement
	if newVolumeSetting is greater than 100 then set newVolumeSetting to 100
	setOutputVolumeLevel(newVolumeSetting)
	tell current application to say (newVolumeSetting as text)
	-- store the JXA call to this handler
	set JXACommandString to "Library('DC-Workspace').increaseOutputVolumeByDefaultIncrement();"
	tell script "DC-Support" to storeJXACommandString(JXACommandString)
end increaseOutputVolumeByDefaultIncrement

on decreaseOutputVolumeByDefaultIncrement()
	set currentVolumeSetting to getCurrentOutputVolume()
	set newVolumeSetting to currentVolumeSetting - defaultVolumeIncrement
	if newVolumeSetting is less than 0 then set newVolumeSetting to 0
	setOutputVolumeLevel(newVolumeSetting)
	if newVolumeSetting is 0 then
		tell current application to beep
	else
		tell current application to say (newVolumeSetting as text)
	end if
	-- store the JXA call to this handler
	set JXACommandString to "Library('DC-Workspace').decreaseOutputVolumeByDefaultIncrement();"
	tell script "DC-Support" to storeJXACommandString(JXACommandString)
end decreaseOutputVolumeByDefaultIncrement

on speakCurrentOutputVolumeLevel()
	tell current application to say (my getCurrentOutputVolume() as text)
	-- store the JXA call to this handler
	set JXACommandString to "Library('DC-Workspace').speakCurrentOutputVolumeLevel();"
	tell script "DC-Support" to storeJXACommandString(JXACommandString)
end speakCurrentOutputVolumeLevel

on getCurrentInputVolume()
	try
		tell current application
			return (input volume of (get volume settings))
		end tell
	on error errorMessage
		beep
		my logThis(errorMessage)
	end try
end getCurrentInputVolume

on getCurrentOutputVolume()
	try
		tell current application
			return (output volume of (get volume settings))
		end tell
	on error errorMessage
		beep
		my logThis(errorMessage)
	end try
end getCurrentOutputVolume

on setInputVolumeLevel(volumeLevel)
	try
		set volumeLevel to volumeLevel as integer
		if volumeLevel is less than 0 then
			set volumeLevel to 0
		else if volumeLevel is greater than 100 then
			set volumeLevel to 100
		end if
		tell current application
			set volume input volume volumeLevel
		end tell
	on error errorMessage
		beep
		my logThis(errorMessage)
	end try
end setInputVolumeLevel

on setOutputVolumeLevel(volumeLevel)
	try
		set volumeLevel to volumeLevel as integer
		if volumeLevel is less than 0 then
			set volumeLevel to 0
		else if volumeLevel is greater than 100 then
			set volumeLevel to 100
		end if
		tell current application
			set volume output volume volumeLevel
		end tell
	on error errorMessage
		beep
		my logThis(errorMessage)
	end try
end setOutputVolumeLevel

on getOutputVolumeMuteState()
	try
		tell current application
			set currentVolumeMuteState to output muted of (get volume settings)
			return currentVolumeMuteState
		end tell
	on error errorMessage
		beep
		my logThis(errorMessage)
	end try
end getOutputVolumeMuteState

on setOutputVolumeMute(shouldMute)
	try
		tell current application
			if shouldMute is true then
				set volume with output muted
			else
				set volume without output muted
			end if
		end tell
	on error errorMessage
		beep
		my logThis(errorMessage)
	end try
end setOutputVolumeMute

(* TEXT-TO-AUDIO RENDERING *)

on renderClipboardStringToAudioFile(shouldRevealInFinder)
	if (clipboard info for «class utf8») is not {} then
		set clipboardString to (get the clipboard as «class utf8»)
		set renderResult to renderAndEncode(clipboardString)
		if renderResult is false then
			my speakWithMutedInput("PROBLEM_RENDERING_AUDIO")
		else
			if shouldRevealInFinder is true then
				revealInFinder(renderResult)
			end if
			announceCompletion()
			return renderResult
		end if
	else
		my speakWithMutedInput("NO_TEXT_ON_CLIPBOARD")
	end if
end renderClipboardStringToAudioFile

(* handler for rendering a string to an encoded MPEG audio file *)
on renderAndEncode(thisString)
	if thisString is "" then
		return false
	else
		-- get the path to the temp folder
		set the temporaryItemsFolder to the POSIX path of (path to music folder)
		-- derive unique names for the audio files
		set baseName to generateNameWithAppendedDateTime("AUDIO-FROM-TEXT")
		set audioAIFFFileName to baseName & ".aiff"
		set audioMPEGFileName to baseName & ".m4a"
		-- construct the paths to the files to be created
		set targetAIFFFilePath to temporaryItemsFolder & audioAIFFFileName
		set targetMPEGFilePath to temporaryItemsFolder & audioMPEGFileName
		-- render text to AIFF audio file
		do shell script "say" & space & "-o" & space & quoted form of targetAIFFFilePath & space & quoted form of thisString
		-- encode audio file to MPEG
		do shell script "afconvert -f 'm4af' -d 'aac ' -s 1 " & (quoted form of targetAIFFFilePath) & space & (quoted form of targetMPEGFilePath)
		-- delete source audio file
		do shell script "rm -f " & (quoted form of targetAIFFFilePath)
		-- return reference to encoded audio file
		return (targetMPEGFilePath as POSIX file as alias)
	end if
end renderAndEncode

(* MOVE FINDER SELECTION *)

-- move into shared items folder
on moveFinderSelectionIntoSharedItemsFolder(shouldReplace, shouldRevealInFinder)
	set destinationFolderPath to getPathForSharedItemsDirectory(false)
	moveFinderSelectionIntoSpecifiedFolder(destinationFolderPath, shouldReplace, shouldRevealInFinder)
end moveFinderSelectionIntoSharedItemsFolder

-- move into documents folder
on moveFinderSelectionIntoDocumentsFolder(shouldReplace, shouldRevealInFinder)
	set destinationFolderPath to getPathForUserDocumentsDirectory(false)
	moveFinderSelectionIntoSpecifiedFolder(destinationFolderPath, shouldReplace, shouldRevealInFinder)
end moveFinderSelectionIntoDocumentsFolder

-- move into pictures folder
on moveFinderSelectionIntoPicturesFolder(shouldReplace, shouldRevealInFinder)
	set destinationFolderPath to getPathForUserPicturesDirectory(false)
	moveFinderSelectionIntoSpecifiedFolder(destinationFolderPath, shouldReplace, shouldRevealInFinder)
end moveFinderSelectionIntoPicturesFolder

-- move into public folder
on moveFinderSelectionIntoPublicFolder(shouldReplace, shouldRevealInFinder)
	set destinationFolderPath to getPathForUserPublicDirectory(false)
	moveFinderSelectionIntoSpecifiedFolder(destinationFolderPath, shouldReplace, shouldRevealInFinder)
end moveFinderSelectionIntoPublicFolder

-- move into movies folder
on moveFinderSelectionIntoMoviesFolder(shouldReplace, shouldRevealInFinder)
	set destinationFolderPath to getPathForUserMoviesDirectory(false)
	moveFinderSelectionIntoSpecifiedFolder(destinationFolderPath, shouldReplace, shouldRevealInFinder)
end moveFinderSelectionIntoMoviesFolder

-- move into music folder
on moveFinderSelectionIntoMusicFolder(shouldReplace, shouldRevealInFinder)
	set destinationFolderPath to getPathForUserMusicDirectory(false)
	moveFinderSelectionIntoSpecifiedFolder(destinationFolderPath, shouldReplace, shouldRevealInFinder)
end moveFinderSelectionIntoMusicFolder

-- move into desktop folder
on moveFinderSelectionIntoDesktopFolder(shouldReplace, shouldRevealInFinder)
	set destinationFolderPath to getPathForUserDesktopDirectory(false)
	moveFinderSelectionIntoSpecifiedFolder(destinationFolderPath, shouldReplace, shouldRevealInFinder)
end moveFinderSelectionIntoDesktopFolder

-- move into user applications folder
on moveFinderSelectionIntoUserApplicationsFolder(shouldReplace, shouldRevealInFinder)
	set destinationFolderPath to getPathForUserApplicationsDirectory(false)
	moveFinderSelectionIntoSpecifiedFolder(destinationFolderPath, shouldReplace, shouldRevealInFinder)
end moveFinderSelectionIntoUserApplicationsFolder

-- move into applications folder
on moveFinderSelectionIntoApplicationsFolder(shouldReplace, shouldRevealInFinder)
	set destinationFolderPath to getPathForApplicationsDirectory(true)
	displaySpokenErrorAlert("COPY_TO_APPLICATIONS_FOLDER_PROMPT", appID)
end moveFinderSelectionIntoApplicationsFolder

on moveFinderSelectionIntoSpecifiedFolder(destinationFolderPath, shouldReplace, shouldRevealInFinder)
	try
		tell application id "com.apple.finder"
			set selectedItems to (get selection as alias list)
		end tell
		if selectedItems is {} then error "NO_FINDER_SELECTION"
		set movedItems to {}
		repeat with i from 1 to the count of selectedItems
			set thisItem to item i of selectedItems
			if shouldReplace is true then
				set the end of movedItems to (its moveItem:thisItem intoFolder:destinationFolderPath withReplacing:true)
			else
				set the end of movedItems to (its moveItem:thisItem uniquelyToFolder:destinationFolderPath)
			end if
		end repeat
		if shouldRevealInFinder is true then
			revealInFinder(movedItems)
		end if
		announceCompletion()
	on error errorMessage number errorNumber
		my logThis(errorMessage)
		if errorNumber is not -128 and errorMessage is not missing value then
			my displaySpokenErrorAlert(errorMessage, "")
		end if
		error number -128
	end try
end moveFinderSelectionIntoSpecifiedFolder


(* DESIGNATED FOLDERS *)

on getPathForUserLibraryDirectory(shouldOpenDirectory)
	set aFileManager to current application's NSFileManager's defaultManager
	set resultArray to aFileManager's URLsForDirectory:(current application's NSLibraryDirectory) inDomains:(current application's NSUserDomainMask)
	set aURL to (item 1 of resultArray)
	if shouldOpenDirectory is true then
		set aWorkspace to current application's NSWorkspace's sharedWorkspace
		aWorkspace's openURL:aURL
	end if
	return (|path|() of aURL) as text
end getPathForUserLibraryDirectory

on getPathForLocalLibraryDirectory(shouldOpenDirectory)
	set aFileManager to current application's NSFileManager's defaultManager
	set resultArray to aFileManager's URLsForDirectory:(current application's NSLibraryDirectory) inDomains:(current application's NSLocalDomainMask)
	set aURL to (item 1 of resultArray)
	if shouldOpenDirectory is true then
		set aWorkspace to current application's NSWorkspace's sharedWorkspace
		aWorkspace's openURL:aURL
	end if
	return (|path|() of aURL) as text
end getPathForLocalLibraryDirectory

on getPathForUserDownloadsDirectory(shouldOpenDirectory)
	set aFileManager to current application's NSFileManager's defaultManager
	set resultArray to aFileManager's URLsForDirectory:(current application's NSDownloadsDirectory) inDomains:(current application's NSUserDomainMask)
	set aURL to (item 1 of resultArray)
	if shouldOpenDirectory is true then
		set aWorkspace to current application's NSWorkspace's sharedWorkspace
		aWorkspace's openURL:aURL
	end if
	return (|path|() of aURL) as text
end getPathForUserDownloadsDirectory

on getPathForUserPicturesDirectory(shouldOpenDirectory)
	set aFileManager to current application's NSFileManager's defaultManager
	set resultArray to aFileManager's URLsForDirectory:(current application's NSPicturesDirectory) inDomains:(current application's NSUserDomainMask)
	set aURL to (item 1 of resultArray)
	if shouldOpenDirectory is true then
		set aWorkspace to current application's NSWorkspace's sharedWorkspace
		aWorkspace's openURL:aURL
	end if
	return (|path|() of aURL) as text
end getPathForUserPicturesDirectory

on getPathForUserPublicDirectory(shouldOpenDirectory)
	set aFileManager to current application's NSFileManager's defaultManager
	set resultArray to aFileManager's URLsForDirectory:(current application's NSSharedPublicDirectory) inDomains:(current application's NSUserDomainMask)
	set aURL to (item 1 of resultArray)
	if shouldOpenDirectory is true then
		set aWorkspace to current application's NSWorkspace's sharedWorkspace
		aWorkspace's openURL:aURL
	end if
	return (|path|() of aURL) as text
end getPathForUserPublicDirectory

on getPathForUserMoviesDirectory(shouldOpenDirectory)
	set aFileManager to current application's NSFileManager's defaultManager
	set resultArray to aFileManager's URLsForDirectory:(current application's NSMoviesDirectory) inDomains:(current application's NSUserDomainMask)
	set aURL to (item 1 of resultArray)
	if shouldOpenDirectory is true then
		set aWorkspace to current application's NSWorkspace's sharedWorkspace
		aWorkspace's openURL:aURL
	end if
	return (|path|() of aURL) as text
end getPathForUserMoviesDirectory

on getPathForUserMusicDirectory(shouldOpenDirectory)
	set aFileManager to current application's NSFileManager's defaultManager
	set resultArray to aFileManager's URLsForDirectory:(current application's NSMusicDirectory) inDomains:(current application's NSUserDomainMask)
	set aURL to (item 1 of resultArray)
	if shouldOpenDirectory is true then
		set aWorkspace to current application's NSWorkspace's sharedWorkspace
		aWorkspace's openURL:aURL
	end if
	return (|path|() of aURL) as text
end getPathForUserMusicDirectory

on getPathForUserDocumentsDirectory(shouldOpenDirectory)
	set aFileManager to current application's NSFileManager's defaultManager
	set resultArray to aFileManager's URLsForDirectory:(current application's NSDocumentDirectory) inDomains:(current application's NSUserDomainMask)
	set aURL to (item 1 of resultArray)
	if shouldOpenDirectory is true then
		set aWorkspace to current application's NSWorkspace's sharedWorkspace
		aWorkspace's openURL:aURL
	end if
	return (|path|() of aURL) as text
end getPathForUserDocumentsDirectory

on getPathForUserDesktopDirectory(shouldOpenDirectory)
	set aFileManager to current application's NSFileManager's defaultManager
	set resultArray to aFileManager's URLsForDirectory:(current application's NSDesktopDirectory) inDomains:(current application's NSUserDomainMask)
	set aURL to (item 1 of resultArray)
	if shouldOpenDirectory is true then
		set aWorkspace to current application's NSWorkspace's sharedWorkspace
		aWorkspace's openURL:aURL
	end if
	return (|path|() of aURL) as text
end getPathForUserDesktopDirectory

on getPathForApplicationsDirectory(shouldOpenDirectory)
	set aFileManager to current application's NSFileManager's defaultManager
	set resultArray to aFileManager's URLsForDirectory:(current application's NSApplicationDirectory) inDomains:(current application's NSLocalDomainMask)
	log resultArray
	set aURL to (item 1 of resultArray)
	if shouldOpenDirectory is true then
		set aWorkspace to current application's NSWorkspace's sharedWorkspace
		aWorkspace's openURL:aURL
	end if
	return (|path|() of aURL) as text
end getPathForApplicationsDirectory

on getPathForUserApplicationsDirectory(shouldOpenDirectory)
	set aFileManager to current application's NSFileManager's defaultManager
	set resultArray to aFileManager's URLsForDirectory:(current application's NSApplicationDirectory) inDomains:(current application's NSUserDomainMask)
	log resultArray
	set aURL to (item 1 of resultArray)
	if shouldOpenDirectory is true then
		set aWorkspace to current application's NSWorkspace's sharedWorkspace
		aWorkspace's openURL:aURL
	end if
	return (|path|() of aURL) as text
end getPathForUserApplicationsDirectory

on getPathForUsersHomeDirectory(shouldOpenDirectory)
	set aFolderPath to the POSIX path of (path to "cusr")
	if shouldOpenDirectory is true then
		set aURL to current application's class "NSURL"'s fileURLWithPath:aFolderPath
		set aWorkspace to current application's NSWorkspace's sharedWorkspace
		aWorkspace's openURL:aURL
	end if
	return aFolderPath
end getPathForUsersHomeDirectory

on getPathForSharedItemsDirectory(shouldOpenDirectory)
	set aFolderPath to the POSIX path of (path to "sdat")
	if shouldOpenDirectory is true then
		set aURL to current application's class "NSURL"'s fileURLWithPath:aFolderPath
		set aWorkspace to current application's NSWorkspace's sharedWorkspace
		aWorkspace's openURL:aURL
	end if
	return aFolderPath
end getPathForSharedItemsDirectory

on getPathForiCloudDriveDirectory(shouldOpenDirectory)
	set aFolderPath to the POSIX path of (path to library folder from user domain)
	set aFolderPath to aFolderPath & "Mobile Documents/com~apple~CloudDocs"
	if shouldOpenDirectory is true then
		set aURL to current application's class "NSURL"'s fileURLWithPath:aFolderPath
		set aWorkspace to current application's NSWorkspace's sharedWorkspace
		aWorkspace's openURL:aURL
	end if
	return aFolderPath
end getPathForiCloudDriveDirectory




(* SPOTLIGHT *)

on searchUsingUserTagsOfSelectedItem()
	try
		tell application id "com.apple.finder"
			set selectedItems to (get selection as alias list)
			if (count of selectedItems) is not 1 then error "SELECT_SINGLE_ITEM"
			set targetItem to item 1 of selectedItems
			set itemName to name of targetItem
			set thisFilePath to the POSIX path of targetItem
		end tell
		
		## GET THE TAGS FOR THE FRONT DOCUMENT FILE
		set thisURL to current application's class "NSURL"'s fileURLWithPath:thisFilePath
		set {theResult, theTags, theError} to thisURL's getResourceValue:(reference) forKey:(current application's NSURLTagNamesKey) |error|:(reference)
		if theResult as boolean is false then error (theError's |localizedDescription|() as text)
		--if theTags = missing value then return {} -- because when there are none, it returns missing value
		--return theTags as list
		
		set itemTitle to current application's class "NSString"'s stringWithString:itemName
		set itemTitle to itemTitle's stringByDeletingPathExtension()
		set itemTitle to (itemTitle's stringByReplacingOccurrencesOfString:"\"" withString:"") as string
		
		if theTags is {} or theTags is missing value then
			set searchString to "name:\"" & itemTitle & "\""
		else if (count of theTags) is 1 then
			set searchString to "name:\"" & itemTitle & "\"" & " OR " & "tag:\"" & (theTags as string) & "\""
		else
			set thisArray to current application's class "NSArray"'s arrayWithArray:theTags
			set searchString to "name:\"" & itemTitle & "\"" & " OR " & "tag:\"" & (thisArray's componentsJoinedByString:"\" OR tag:\"") as string
		end if
		
		## DO SEARCH IN FINDER
		set aWorkspace to current application's NSWorkspace's sharedWorkspace
		aWorkspace's showSearchResultsForQueryString:searchString
		
	on error errorMessage number errorNumber
		if errorNumber is not -128 then
			my displaySpokenErrorAlert(errorMessage, "")
		end if
		error number -128
	end try
end searchUsingUserTagsOfSelectedItem

(* KEYNOTE *)

on playSelectedKeynoteFile()
	try
		tell application id "com.apple.finder"
			set selectedItems to (get selection as alias list)
			if (count of selectedItems) is not 1 then error "SELECT_SINGLE_PRESENTATION_FILE"
			set selectedItem to item 1 of selectedItems
			set thisFilePath to the POSIX path of selectedItem
		end tell
		set selectedItemID to typeIDForFile(thisFilePath)
		if selectedItemID is not in {"com.apple.iwork.keynote.sffkey", "com.apple.iwork.keynote.key"} then
			error "SELECT_SINGLE_PRESENTATION_FILE"
		else
			tell application id "com.apple.iWork.Keynote"
				activate
				open selectedItem
				«event KnstplaY» the front document given «class kfro»:the first «class KnSd» of the front document
			end tell
		end if
	on error errorMessage number errorNumber
		my logThis(errorMessage)
		if errorNumber is not -128 and errorMessage is not missing value then
			my displaySpokenErrorAlert(errorMessage, "")
		end if
		error number -128
	end try
end playSelectedKeynoteFile

on importSelectedFinderItemIntoKeynote()
	set movieIDs to {"com.apple.m4v-video", "public.mpeg-4", "com.apple.quicktime-movie"}
	set imageIDs to {"public.png", "public.jpeg", "public.tiff"}
	try
		tell application id "com.apple.finder"
			set currrentSelection to (get the selection)
			if (count of currrentSelection) is not 1 then
				error "SELECT_SINGLE_IWORK_COMPATIBLE_ITEM"
			end if
			set thisFileReference to (item 1 of currrentSelection) as alias
		end tell
		set itemID to typeIDForFile(thisFileReference)
		if itemID is not in movieIDs and itemID is not in imageIDs then
			error "SELECT_SINGLE_IWORK_COMPATIBLE_ITEM"
		end if
		if itemID is in imageIDs then
			-- GET METADATA DESCRIPTION
			set imageDescription to getkMDItemDescriptionFromImageFile(thisFileReference)
			if imageDescription is "" then
				set imageDescription to extractkMDItemDescription(thisFileReference)
			end if
		end if
		
		(* GET THE SINGLE IMAGE IN KEYNOTE *)
		set shouldCreateNewImage to false
		tell script "DC-Keynote"
			set selectedItems to getSelectedKeynoteImages()
			set itemCount to count of selectedItems
		end tell
		tell application id "com.apple.iWork.Keynote"
			if itemCount is 0 then -- check for a single unselected image
				tell front document
					tell «class crsl»
						set imageCount to the count of every «class imag» of it
						if imageCount is 0 then
							-- error "NO_IMAGES_ON_SLIDE"
							set shouldCreateNewImage to true
						else if imageCount is 1 then
							set targetImageRef to «class imag» 1
						else -- more than one selected
							error "SELECT_SINGLE_IMAGE_SLIDE_ITEM"
						end if
					end tell
				end tell
			else if itemCount is 1 then
				set targetImageRef to item 1 of selectedItems
			else -- more than one selected
				error "SELECT_SINGLE_IMAGE_SLIDE_ITEM"
			end if
		end tell
		
		(* IMPORT IMAGE *)
		(* NOTE: movies will import using the image object *)
		say (getLocalizedStringForKey("ANNOUNCE_IMPORT_START"))
		tell application id "com.apple.iWork.Keynote"
			activate
			tell front document
				tell «class crsl»
					if shouldCreateNewImage is true then
						set newImageItem to make new «class imag» with properties {file:thisFileReference}
						if itemID is in imageIDs then
							set «class dscr» of newImageItem to imageDescription
						end if
					else
						set «class atfn» of targetImageRef to thisFileReference
						if itemID is in imageIDs then
							set «class dscr» of targetImageRef to imageDescription
						end if
					end if
				end tell
			end tell
		end tell
		
		announceCompletion()
		
		-- store the JXA call to this handler
		set JXACommandString to "Library('DC-Photos').importSelectedFinderItemIntoKeynote();"
		tell script "DC-Support" to storeJXACommandString(JXACommandString)
	on error errorMessage number errorNumber
		if errorNumber is not -128 then
			my displaySpokenErrorAlert(errorMessage, "com.apple.iWork.Keynote")
		end if
		error number -128
	end try
end importSelectedFinderItemIntoKeynote

(* WINDOWS *)

on closeEveryFinderWindow()
	tell application id "com.apple.finder"
		activate
		close Finder windows
	end tell
end closeEveryFinderWindow

on closeEveryFinderWindowExceptTopWindow()
	tell application id "com.apple.finder"
		activate
		set fWindowCount to the count of Finder windows
		if fWindowCount is greater than 1 then
			repeat with i from fWindowCount to 2 by -1
				close Finder window i
			end repeat
		end if
	end tell
end closeEveryFinderWindowExceptTopWindow

(* WORKSPACE *)

on hideNonFrontmostApplications()
	tell application id "com.apple.systemevents"
		set visible of every process whose frontmost is not true to false
	end tell
end hideNonFrontmostApplications

on launchApplicationFileByID(appBundleID)
	try
		set aWorkspace to current application's NSWorkspace's sharedWorkspace
		set appPath to (aWorkspace's absolutePathForAppBundleWithIdentifier:appBundleID)
		if appPath is missing value then error getLocalizedStringForKey("APP_NOT_LAUNCH")
		set appfileURL to current application's class "NSURL"'s fileURLWithPath:appPath
		set runningApp to aWorkspace's launchApplicationAtURL:appfileURL options:(current application's NSWorkspaceLaunchDefault) configuration:(missing value) |error|:(missing value)
	on error errMsg number errNum
		displaySpokenErrorAlert(errMsg, "")
		error number -128
	end try
end launchApplicationFileByID

on pathOfFolderOfCurrentApplicationFile()
	set aWorkspace to current application's NSWorkspace's sharedWorkspace
	set frontmostApp to aWorkspace's frontmostApplication
	set appID to (frontmostApp's bundleIdentifier) as text
	set appBundleURL to (frontmostApp's bundleURL)
	set aPath to appBundleURL's |path|()
	return (aPath's stringByDeletingLastPathComponent()) as text
end pathOfFolderOfCurrentApplicationFile

on speakLocalizedNameOfFrontmostApplication()
	set appName to getLocalizedNameOfCurrentApplicationFile()
	set the promptMessage to getLocalizedStringForKey("NAME_OF_FRONT_APP_MESSAGE")
	say (promptMessage & appName)
end speakLocalizedNameOfFrontmostApplication

on getLocalizedNameOfCurrentApplicationFile()
	set aWorkspace to current application's NSWorkspace's sharedWorkspace
	set frontmostApp to aWorkspace's frontmostApplication
	set appName to (frontmostApp's localizedName) as text
	return appName
end getLocalizedNameOfCurrentApplicationFile




(* SUPPORT HANDLERS *)

on getIDOfFrontmostApplication()
	set aWorkspace to current application's NSWorkspace's sharedWorkspace
	set frontmostApp to aWorkspace's frontmostApplication
	set appID to (frontmostApp's bundleIdentifier) as text
	return appID
end getIDOfFrontmostApplication

on writeToFile(thisData, targetFile, appendData)
	tell current application
		try
			set the targetFile to the targetFile as string
			set the open_targetFile to open for access file targetFile with write permission
			if appendData is false then set eof of the open_targetFile to 0
			write thisData to the open_targetFile starting at eof
			close access the open_targetFile
			return true
		on error errorMessageString
			try
				close access file targetFile
			end try
			log ("ACTION ERROR: " & errorMessageString)
			return false
		end try
	end tell
end writeToFile

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
	return (localized string thisKey in bundle thisBundlePath)
end getLocalizedStringForKey

on announceCompletion()
	say my getLocalizedStringForKey("SUCCESSFUL_COMPLETION_PHRASE")
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


