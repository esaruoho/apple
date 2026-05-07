use AppleScript version "2.5"
use framework "Foundation"
use framework "AppKit"
use framework "MapKit"
use framework "CoreLocation"
-- use framework "AddressBook"
use framework "CoreImage"
use framework "CoreGraphics"
use scripting additions

property logEnabled : true

(* SELECT *)

on doSelectAll()
	tell application id "com.apple.Photos" to activate
	tell application "System Events"
		tell process "Photos"
			keystroke "a" using command down
		end tell
	end tell
	tell current application to delay 1
	tell application id "com.apple.Photos"
		set theseItems to (get selection)
		set itemCount to count of theseItems
	end tell
	tell script "DC-Assistive-Photos"
		set itemTerm to pluralizeThisNoun("item", itemCount)
		set isAreTerm to isOrAre(itemCount)
		set countTerm to convertToNoForZero(itemCount) as text
	end tell
	set termForSelected to getLocalizedStringForKey("TERM_FOR_SELECTED")
	tell current application
		say (countTerm & space & itemTerm & space & isAreTerm & space & termForSelected & ".") as text
	end tell
end doSelectAll

(* SHOW *)
on showAllPhotos()
	-- SHOW ALL PHOTOS
	tell application id "com.apple.Photos"
		activate
		set currentVersion to (get version of it)
	end tell
	if currentVersion is greater than or equal to "2.0" then
		tell application "System Events" to keystroke "1" using command down
	else
		tell application "System Events" to keystroke "1" using command down
	end if
	set stringToSpeak to getLocalizedStringForKey("TERM_FOR_ALL_PHOTOS_SHOWING")
	tell current application
		say stringToSpeak
	end tell
end showAllPhotos

on showAllAlbums()
	-- SHOW ALL ALBUMS
	tell application id "com.apple.Photos"
		activate
		set currentVersion to (get version of it)
	end tell
	if currentVersion is greater than or equal to "2.0" then
		open location "photos:albums"
	else
		tell application "System Events" to keystroke "3" using command down
	end if
	set stringToSpeak to getLocalizedStringForKey("TERM_FOR_ALL_ALBUMS_SHOWING")
	tell current application
		say stringToSpeak
	end tell
end showAllAlbums

on showSharedItems()
	-- SHOW SHARED ITEMS
	tell application id "com.apple.Photos"
		activate
		set currentVersion to (get version of it)
	end tell
	if currentVersion is greater than or equal to "2.0" then
		open location "photos:sharing"
	else
		tell application "System Events" to keystroke "3" using command down
	end if
	set stringToSpeak to getLocalizedStringForKey("TERM_FOR_SHARED_ITEMS_SHOWING")
	tell current application
		say stringToSpeak
	end tell
end showSharedItems

on showLastImportAlbum()
	-- SHOW LAST IMPORT
	tell application id "com.apple.Photos"
		activate
		set currentVersion to (get version of it)
	end tell
	if currentVersion is greater than or equal to "2.0" then
		open location "photos:albums?albumUuid=lastImportAlbum"
		set stringToSpeak to getLocalizedStringForKey("TERM_FOR_LAST_IMPORT_ALBUM_SHOWING")
		tell current application
			say stringToSpeak
		end tell
	else
		beep
	end if
end showLastImportAlbum

on showFavoritesAlbum()
	-- SHOW FAVORITES ALBUM
	tell application id "com.apple.Photos"
		activate
		set currentVersion to (get version of it)
	end tell
	if currentVersion is greater than or equal to "2.0" then
		open location "photos:albums?albumUuid=favoritesAlbum"
		set stringToSpeak to getLocalizedStringForKey("TERM_FOR_FAVORITES_SHOWING")
		tell current application
			say stringToSpeak
		end tell
	else
		beep
	end if
end showFavoritesAlbum

(* KEYWORDS *)

on showSmartAlbumForRating(ratingIndex)
	try
		tell application id "com.apple.Photos"
			activate
			set currentVersion to (get version of it)
		end tell
		if currentVersion is greater than or equal to "2.0" then
			set ratingName to ""
			repeat ratingIndex times
				set ratingName to ratingName & "★"
			end repeat
			tell application id "com.apple.Photos"
				set aID to id of first album whose name is ratingName
			end tell
			open location "photos:albums?albumUuid="
			announceCompletion()
		else
			error "fail"
		end if
	on error
		beep
	end try
end showSmartAlbumForRating

on setupRatingsKeywords()
	try
		tell application id "com.apple.Photos"
			activate
			set currentVersion to (get version of it)
			set theseMediaItems to (get selection)
			if the (count of theseMediaItems) is not 1 then
				error "SELECT_SINGLE_ITEM_IN_PHOTOS"
			end if
			set thisItem to item 1 of theseMediaItems
			set storedKeywords to keywords of thisItem
			if storedKeywords is missing value then set storedKeywords to {}
			set keywords of thisItem to {"★", "★★", "★★★", "★★★★", "★★★★★"}
			get keywords of thisItem
			--> {"★", "★★", "★★★", "★★★★", "★★★★★"}
			set keywords of thisItem to storedKeywords
			set the clipboard to "★"
		end tell
		tell application "System Events"
			tell process "Photos"
				try
					first window whose subrole is "AXFloatingWindow" and title is "Keywords"
				on error
					keystroke "k" using command down
				end try
			end tell
		end tell
		announceCompletion()
	on error errorMessage number errorNumber
		my displaySpokenErrorAlert(errorMessage, "com.apple.Photos")
		error number -128
	end try
end setupRatingsKeywords

on searchForItemsWithRating(ratingIndex)
	set thisRatingString to item ratingIndex of {"★", "★★", "★★★", "★★★★", "★★★★★"}
	tell application id "com.apple.Photos"
		activate
		try
			tell application "System Events"
				tell process "Photos"
					keystroke "f" using command down
					delay 1
					repeat with i from the (count of windows) to 1 by -1
						if subrole of window i is "AXStandardWindow" then
							if description of window i is "Photos" then
								-- do nothing
							else
								click button 1 of window i
								delay 0.5
							end if
						end if
					end repeat
					set mainWindow to first window whose subrole is "AXStandardWindow" and description is "Photos"
					set windowToolbar to toolbar 1 of mainWindow
					set theseElements to the entire contents of windowToolbar
					set searchField to missing value
					repeat with i from 1 to the count of theseElements
						set thisElement to item i of theseElements
						if the class of thisElement is text field and subrole of thisElement is "AXSearchField" then
							set searchField to thisElement
							set value of searchField to thisRatingString
							select searchField
							-- select searchField
							exit repeat
						end if
					end repeat
					if searchField is missing value then error number -128
				end tell
			end tell
		on error
			beep
		end try
	end tell
end searchForItemsWithRating

on setRatingOfSelectedItemsTo(ratingIndex)
	tell application id "com.apple.Photos"
		activate
		set theseItems to (get the selection)
		repeat with i from 1 to the count of theseItems
			set thisItem to item i of theseItems
			my setRating(thisItem, ratingIndex)
		end repeat
	end tell
	announceCompletion()
end setRatingOfSelectedItemsTo

on setRating(thisItem, ratingIndex)
	set ratingsList to {"★", "★★", "★★★", "★★★★", "★★★★★"}
	tell application id "com.apple.Photos"
		my removeStarRatingKeywordsFromItem(thisItem)
		if ratingIndex is not 0 then
			my appendKeyword(thisItem, (item ratingIndex of ratingsList))
		end if
	end tell
end setRating

on appendKeyword(thisItem, thisKeyword)
	tell application id "com.apple.Photos"
		set storedKeywords to keywords of thisItem
		if storedKeywords is missing value then set storedKeywords to {}
		if storedKeywords does not contain thisKeyword then
			set the end of storedKeywords to thisKeyword
		end if
		set keywords of thisItem to storedKeywords
	end tell
end appendKeyword

on removeStarRatingKeywordsFromItem(thisItem)
	tell application id "com.apple.Photos"
		set storedKeywords to keywords of thisItem
		if storedKeywords is missing value then set storedKeywords to {}
		set ratingsList to {"★", "★★", "★★★", "★★★★", "★★★★★"}
		repeat with i from 1 to the count of ratingsList
			set thisRating to item i of ratingsList
			set storedKeywords to my deleteOccurencesOfItemFromList(thisRating, storedKeywords)
		end repeat
		set keywords of thisItem to storedKeywords
	end tell
end removeStarRatingKeywordsFromItem

on insertItemInList(anItem, theIndex, theList)
	set theArray to current application's NSMutableArray's arrayWithArray:theList
	theArray's insertObject:anItem atIndex:(theIndex - 1)
	return theArray as list
end insertItemInList

on deleteOccurencesOfItemFromList(anItem, theList)
	set theArray to current application's NSMutableArray's arrayWithArray:theList
	theArray's removeObject:anItem
	return theArray as list
end deleteOccurencesOfItemFromList

(* FAVORITES *)

on addSelectedMediaItemsToFavorites()
	try
		tell application id "com.apple.Photos"
			activate
			set theseMediaItems to (get selection)
			if theseMediaItems is {} then
				error "NO_ITEMS_SELECTED_IN_PHOTOS"
			end if
			set mediaItemCount to the count of theseMediaItems
			repeat with i from 1 to mediaItemCount
				set favorite of (item i of theseMediaItems) to true
			end repeat
		end tell
		announceCompletion()
	on error errorMessage number errorNumber
		return errorMessage
		my displaySpokenErrorAlert(errorMessage, "com.apple.Photos")
		error number -128
	end try
end addSelectedMediaItemsToFavorites

on removeSelectedMediaItemsFromFavorites()
	try
		tell application id "com.apple.Photos"
			activate
			set theseMediaItems to (get selection)
			if theseMediaItems is {} then
				error "NO_ITEMS_SELECTED_IN_PHOTOS"
			end if
			set mediaItemCount to the count of theseMediaItems
			repeat with i from 1 to mediaItemCount
				set favorite of (item i of theseMediaItems) to false
			end repeat
		end tell
		announceCompletion()
	on error errorMessage number errorNumber
		return errorMessage
		my displaySpokenErrorAlert(errorMessage, "com.apple.Photos")
		error number -128
	end try
end removeSelectedMediaItemsFromFavorites



(* EDIT *)

on editCurrentImage()
	try
		tell application id "com.apple.Photos"
			activate
			set currentVersion to (get version of it)
			set theseMediaItems to (get selection)
			if the (count of theseMediaItems) is not 1 then
				error "SELECT_SINGLE_ITEM_IN_PHOTOS"
			end if
			set thisItem to item 1 of theseMediaItems
			set thisPhotosID to (id of thisItem) as string
		end tell
		if currentVersion is greater than or equal to "2.0" then
			set thisImageID to my replaceStringInString(thisPhotosID, "%", "%25")
			tell current application
				-- photos:oneup/asset?assetUuid
				open location "photos:oneup/asset?assetUuid=" & thisImageID & "&editMode=1"
			end tell
		else
			tell application "System Events" to keystroke return
		end if
	on error errorMessage number errorNumber
		my displaySpokenErrorAlert(errorMessage, "com.apple.Photos")
		error number -128
	end try
end editCurrentImage

on editImageByID(thisImageID)
	try
		tell application id "com.apple.Photos"
			activate
			set currentVersion to (get version of it)
			if not (exists media item id thisImageID) then
				error "MEDIA_ITEM_NOT_FOUND"
			end if
		end tell
		if currentVersion is greater than or equal to "2.0" then
			set thisImageID to findAndReplaceStringInText(thisImageID, "%", "%25")
			tell current application
				open location "photos:oneup/asset?assetUuid=" & thisImageID & "&editMode=1"
			end tell
		else
			tell application id "com.apple.Photos" to spotlight media item id thisImageID
		end if
	on error errorMessage number errorNumber
		my displaySpokenErrorAlert(errorMessage, "com.apple.Photos")
		error number -128
	end try
end editImageByID

on enterCropAdjustmentMode()
	tell application id "com.apple.Photos"
		activate
	end tell
	tell application "System Events"
		keystroke "c"
	end tell
end enterCropAdjustmentMode

on cropSelectedPhoto()
	editCurrentImage()
	delay 2
	enterCropAdjustmentMode()
end cropSelectedPhoto

on exitEditMode()
	set doneButtonTitle to getLocalizedStringForKey("DONE_BUTTON_TITLE")
	set dialogMessage to getLocalizedStringForKey("STOPPING_EDIT_MESSAGE")
	tell application id "com.apple.Photos"
		activate
		activate
		activate
	end tell
	tell application "System Events"
		set localizedPhotosTitle to the name of first process whose bundle identifier is "com.apple.Photos"
		tell process localizedPhotosTitle
			if exists checkbox doneButtonTitle of group 1 of group 1 of toolbar 1 of window 1 then
				click checkbox doneButtonTitle of group 1 of group 1 of toolbar 1 of window 1
				delay 1
				key code 49
			else
				tell application id "com.apple.Photos"
					activate
					display dialog dialogMessage buttons {"•"} default button 1 giving up after 2
				end tell
				try
					click checkbox doneButtonTitle of group 1 of group 1 of toolbar 1 of window 1
					delay 1
					key code 49
				on error errorMessage
					my logThis(errorMessage)
				end try
			end if
		end tell
	end tell
end exitEditMode

on revertEditImageToOriginal()
	set revertButtonTitle to getLocalizedStringForKey("REVERT_TO_ORIGINAL_BUTTON_TITLE")
	tell application id "com.apple.Photos"
		activate
	end tell
	tell application "System Events"
		set localizedPhotosTitle to the name of first process whose bundle identifier is "com.apple.Photos"
		tell process localizedPhotosTitle
			if exists button revertButtonTitle of group 1 of group 1 of toolbar 1 of window 1 then
				if enabled of button revertButtonTitle of group 1 of group 1 of toolbar 1 of window 1 is true then
					click button revertButtonTitle of group 1 of group 1 of toolbar 1 of window 1
				end if
			end if
		end tell
	end tell
end revertEditImageToOriginal

(* KEYWORDS *)

on appendKeywordToSelectedMediaItems(thisKeyword)
	tell application id "com.apple.Photos"
		set theseMediaItems to (get selection)
		if theseMediaItems is {} then
			my displaySpokenErrorAlert("NO_ITEMS_SELECTED_IN_PHOTOS", "com.apple.Photos")
			error number -128
		end if
		set confirmationMessage to my getLocalizedStringForKey("CONFIRM_APPEND_KEYWORD") & thisKeyword
		set queryResult to my askForText(confirmationMessage, "CONFIRMATION_BUTTON_TITLE", "CANCEL_BUTTON_TITLE", thisKeyword, "com.apple.Photos")
		if queryResult is false then
			return "user canceled"
		else
			set thisKeyword to queryResult
		end if
		repeat with i from 1 to the count of theseMediaItems
			set thisMediaItem to item i of theseMediaItems
			my appendKeywordToMediaItem(thisMediaItem, thisKeyword)
		end repeat
	end tell
	say "Done!"
end appendKeywordToSelectedMediaItems

on appendKeywordToMediaItem(thisMediaItem, thisKeyword)
	tell application id "com.apple.Photos"
		set aKeywordList to keywords of thisMediaItem
		if aKeywordList is missing value then set aKeywordList to {}
		if aKeywordList does not contain thisKeyword then
			set the end of aKeywordList to thisKeyword
			set keywords of thisMediaItem to aKeywordList
		end if
	end tell
end appendKeywordToMediaItem

on appendKeywords(thisItem, theseKeywords)
	if class of theseKeywords is not list then set theseKeywords to theseKeywords as list
	tell application id "com.apple.Photos"
		set storedKeywords to keywords of thisItem
		if storedKeywords is missing value then set storedKeywords to {}
		repeat with i from 1 to the count of theseKeywords
			set thisKeyword to item i of theseKeywords
			if storedKeywords does not contain thisKeyword then
				set the end of storedKeywords to thisKeyword
			end if
		end repeat
		set keywords of thisItem to storedKeywords
	end tell
end appendKeywords

on clearAllKeywordsFromSelectedMediaItems()
	tell application id "com.apple.Photos"
		set theseMediaItems to (get selection)
		if theseMediaItems is {} then
			my displaySpokenErrorAlert("NO_ITEMS_SELECTED_IN_PHOTOS", "com.apple.Photos")
			error number -128
		end if
		if my askForConfirmation("DELETE_KEYWORDS_MESSAGE", "CONFIRMATION_BUTTON_TITLE", "CANCEL_BUTTON_TITLE", "com.apple.Photos") is false then return "user canceled"
		repeat with i from 1 to the count of theseMediaItems
			set thisMediaItem to item i of theseMediaItems
			my clearAllKeywordsFromMediaItem(thisMediaItem)
		end repeat
	end tell
	say "Done!"
end clearAllKeywordsFromSelectedMediaItems

on clearAllKeywordsFromMediaItem(thisMediaItem)
	tell application id "com.apple.Photos"
		set keywords of thisMediaItem to {}
	end tell
end clearAllKeywordsFromMediaItem

(* SHOW *)

on showSelectedPhotoInKeynote()
	tell application id "com.apple.Photos"
		set theseMediaItems to (get selection)
		if the (count of theseMediaItems) is not 1 then
			my displaySpokenErrorAlert("SELECT_SINGLE_ITEM_IN_PHOTOS", "com.apple.Photos")
			error number -128
		end if
		set thisItem to item 1 of theseMediaItems
		set targetID to (id of thisItem) as string
		set thisTitle to name of thisItem
	end tell
	if running of application id "com.apple.iWork.Keynote" is true then
		if (count of documents of application id "com.apple.iWork.Keynote") is 0 then
			my displaySpokenErrorAlert("NO_KEYNOTE_DOCUMENT", "com.apple.Photos")
			error number -128
		else
			tell application id "com.apple.iWork.Keynote"
				if «class Plng» is true then
					tell application id "com.apple.iWork.Keynote"
						tell front document to «event KnststoP»
					end tell
				end if
			end tell
			-- look for image with matching ID
			tell application id "com.apple.iWork.Keynote"
				activate
				set theseSlides to every «class KnSd» of the front document whose «class Kskp» is false
				if theseSlides is {} then
					my displaySpokenErrorAlert("NO_UNSKIPPED_SLIDES", "com.apple.iWork.Keynote")
					error number -128
				end if
				repeat with i from 1 to the count of theseSlides
					set thisSlide to item i of theseSlides
					set theseImages to every «class imag» of thisSlide
					repeat with q from 1 to the count of theseImages
						set thisImage to item q of theseImages
						set thisImageName to (the «class atfn» of thisImage) as string
						if thisImageName begins with targetID then
							-- show the slide by creating and deleting a shape on it
							tell thisSlide
								set thisShape to make new «class sshp»
								delete thisShape
							end tell
							return thisSlide
						end if
					end repeat
				end repeat
			end tell
		end if
		my displaySpokenErrorAlert("PHOTO_IMAGE_NOT_MATCHED", "com.apple.iWork.Keynote")
		error number -128
	else
		my displaySpokenErrorAlert("NO_KEYNOTE_DOCUMENT", "com.apple.Photos")
		error number -128
	end if
end showSelectedPhotoInKeynote

(* MAPS *)

on generateMapShowingLocationsOfSelectedItems()
	tell application id "com.apple.Photos"
		set theseMediaItems to (get selection)
		if theseMediaItems is {} then
			my displaySpokenErrorAlert("NO_ITEMS_SELECTED_IN_PHOTOS", "com.apple.Photos")
			error number -128
		end if
		my showPhotosItemsInMaps(theseMediaItems)
	end tell
end generateMapShowingLocationsOfSelectedItems

on showPhotosItemsInMaps(theseMediaItems)
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
					log thisTitle
					if thisTitle is missing value or thisTitle is "" then
						set thisTitle to filename of thisMediaItem
						log thisTitle
					end if
					set thisID to the id of thisMediaItem
					log thisID
					set encodedID to my encodeReservedCharactersUsingPercentEncoding(thisID)
					log encodedID
					set thisURL to ("photos:oneup/asset?assetUuid=" & encodedID)
					log thisURL
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

(* GOOGLE MAPS *)

on showSelectedItemInGoogleMaps()
	tell application id "com.apple.Photos"
		activate
		try
			set theseMediaItems to my getSelectedMediaItems()
			if theseMediaItems is {} then error number -128
			set libraryPath to the POSIX path of (path to me)
			set helperWorkflowPath to libraryPath & "Contents/Resources/Google Maps.workflow"
			set thisLocation to missing value
			repeat with i from 1 to the count of theseMediaItems
				set thisMediaItem to item i of theseMediaItems
				set thisLocation to the location of thisMediaItem
				if thisLocation is not {missing value, missing value} then
					copy thisLocation to {thisLatitude, thisLongitude}
					exit repeat
				end if
			end repeat
			if thisLocation is missing value then error "NO_LOCATION_DATA"
			set aURL to "http://maps.google.com/?q=" & thisLatitude & "," & ¬
				thisLongitude & "&ll=" & thisLatitude & "," & thisLongitude & "&z=17"
			tell current application
				set commandString to "automator" & space & "-D" & space & "aURL=" & quoted form of aURL & space & quoted form of helperWorkflowPath
				log commandString
				do shell script commandString
			end tell
		on error errorMessage number errorNumber
			if errorNumber is not -128 then
				my displaySpokenErrorAlert(errorMessage, "com.apple.Photos")
			end if
			error number -128
		end try
	end tell
end showSelectedItemInGoogleMaps


(* KEYNOTE *)

on exportPhotosSelectionToNewPresentation()
	try
		tell application id "com.apple.Photos"
			set theseMediaItems to (get selection)
			if theseMediaItems is {} then
				my displaySpokenErrorAlert("NO_ITEMS_SELECTED_IN_PHOTOS", "com.apple.Photos")
				error number -128
			end if
		end tell
		
		-- EXPORT IMAGES WITH IDS FOR FILE NAMES. ENABLES LINKING BACK TO PHOTOS LIBRARY. 
		set exportedImageFiles to quickExport(theseMediaItems, true, false, 2, false, "", "", 1, 1)
		
		tell application id "com.apple.iWork.Keynote"
			activate
			set thisDocument to make new document
			
			set newSlideReferences to {}
			repeat with i from 1 to count of exportedImageFiles
				set thisImageFile to item i of exportedImageFiles
				set thisSlide to my newBlankSlide(thisDocument)
				-- (thisSlide, thisImageFile, scaleToFill, shouldUseDescriptionForNotes)
				my addImageFileToSlide(thisDocument, thisSlide, thisImageFile, true, true)
				set the end of newSlideReferences to thisSlide
			end repeat
			
			set the «class strn» of «class KnSd» 1 of thisDocument to {«class xeft»:«constant tefftdis»}
		end tell
		
		-- MOVE EXPORT FOLDER TO TRASH
		set fileManager to current application's NSFileManager's defaultManager()
		set thisPOSIXPath to the POSIX path of thisImageFile
		set thisPOSIXPath to current application's NSString's stringWithString:thisPOSIXPath
		set pathOfFolderToDelete to thisPOSIXPath's stringByDeletingLastPathComponent()
		set resultingURL to missing value
		set URLOfItemToTrash to (current application's |NSURL|'s fileURLWithPath:pathOfFolderToDelete)
		(fileManager's trashItemAtURL:URLOfItemToTrash resultingItemURL:resultingURL |error|:(missing value))
		
		-- POST NOTIFICATION
		set completitionTitle to (my getLocalizedStringForKey("KEYNOTE_COMPLETITION_TITLE"))
		set completitionMessage to (my getLocalizedStringForKey("KEYNOTE_COMPLETITION_MESSAGE"))
		display notification completitionMessage with title completitionTitle
		
		-- RETURN SLIDE REFERENCES
		tell application id "com.apple.iWork.Keynote"
			return newSlideReferences
		end tell
		
	on error errorMessage number errorNumber
		if errorNumber is not -128 then
			my displaySpokenErrorAlert(errorMessage, "com.apple.iWork.Keynote")
		end if
		error number -128
	end try
end exportPhotosSelectionToNewPresentation

on exportPhotosSelectionToNewSlides()
	try
		tell application id "com.apple.Photos"
			set theseMediaItems to (get selection)
			if theseMediaItems is {} then
				my displaySpokenErrorAlert("NO_ITEMS_SELECTED_IN_PHOTOS", "com.apple.Photos")
				error number -128
			end if
		end tell
		
		-- EXPORT IMAGES WITH IDS FOR FILE NAMES. ENABLES LINKING BACK TO PHOTOS LIBRARY. 
		set exportedImageFiles to quickExport(theseMediaItems, true, false, 2, false, "", "", 1, 1)
		
		tell application id "com.apple.iWork.Keynote"
			activate
			
			if not (exists document 1) then
				set thisDocument to make new document
			else
				set thisDocument to document 1
			end if
			
			set newSlideReferences to {}
			repeat with i from 1 to count of exportedImageFiles
				set thisImageFile to item i of exportedImageFiles
				set thisSlide to my newBlankSlide(thisDocument)
				-- (thisSlide, thisImageFile, scaleToFill, shouldUseDescriptionForNotes)
				my addImageFileToSlide(thisDocument, thisSlide, thisImageFile, true, true)
				set the end of newSlideReferences to thisSlide
			end repeat
			
			set the «class strn» of «class KnSd» 1 of thisDocument to {«class xeft»:«constant tefftdis»}
		end tell
		
		-- MOVE EXPORT FOLDER TO TRASH
		set fileManager to current application's NSFileManager's defaultManager()
		set thisPOSIXPath to the POSIX path of thisImageFile
		set thisPOSIXPath to current application's NSString's stringWithString:thisPOSIXPath
		set pathOfFolderToDelete to thisPOSIXPath's stringByDeletingLastPathComponent()
		set resultingURL to missing value
		set URLOfItemToTrash to (current application's |NSURL|'s fileURLWithPath:pathOfFolderToDelete)
		(fileManager's trashItemAtURL:URLOfItemToTrash resultingItemURL:resultingURL |error|:(missing value))
		
		-- POST NOTIFICATION
		set completitionTitle to (my getLocalizedStringForKey("KEYNOTE_COMPLETITION_TITLE"))
		set completitionMessage to (my getLocalizedStringForKey("KEYNOTE_COMPLETITION_MESSAGE"))
		display notification completitionMessage with title completitionTitle
		
		-- RETURN SLIDE REFERENCES
		tell application id "com.apple.iWork.Keynote"
			return newSlideReferences
		end tell
		
	on error errorMessage number errorNumber
		if errorNumber is not -128 then
			my displaySpokenErrorAlert(errorMessage, "com.apple.iWork.Keynote")
		end if
		error number -128
	end try
end exportPhotosSelectionToNewSlides

on exportSelectedPhotosImageIntoCurrentKeynoteImage()
	(* GET THE SINGLE SELECTED PHOTO *)
	try
		tell application id "com.apple.Photos"
			set currentVersion to (get version of it)
			set theseMediaItems to (get selection)
			if the (count of theseMediaItems) is not 1 then
				error "SELECT_SINGLE_ITEM_IN_PHOTOS"
			end if
			set thisItem to item 1 of theseMediaItems
		end tell
	on error errorMessage number errorNumber
		if errorNumber is not -128 then
			my displaySpokenErrorAlert(errorMessage, "com.apple.Photos")
		end if
		error number -128
	end try
	
	(* GET THE SINGLE IMAGE IN KEYNOTE *)
	set shouldCreateNewImage to false
	try
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
	on error errorMessage number errorNumber
		if errorNumber is not -128 then
			my displaySpokenErrorAlert(errorMessage, "com.apple.iWork.Keynote")
		end if
		error number -128
	end try
	
	(* EXPORT IMAGE AND RETRIEVE DESCRITPION *)
	say (getLocalizedStringForKey("ANNOUNCE_EXPORT_START"))
	try
		tell application id "com.apple.Photos"
			-- EXPORT IMAGES WITH IDS FOR FILE NAMES. ENABLES LINKING BACK TO PHOTOS LIBRARY. 
			set exportedImageFiles to my quickExport(thisItem, true, false, 2, false, "", "", 1, 1)
			set exportedImageFile to item 1 of exportedImageFiles
		end tell
		-- GET METADATA DESCRIPTION
		set imageDescription to getkMDItemDescriptionFromImageFile(exportedImageFile)
		if imageDescription is "" then
			set imageDescription to extractkMDItemDescription(exportedImageFile)
		end if
	on error errorMessage number errorNumber
		if errorNumber is not -128 then
			my displaySpokenErrorAlert(errorMessage, "com.apple.Photos")
		end if
		error number -128
	end try
	
	(* IMPORT IMAGE *)
	say (getLocalizedStringForKey("ANNOUNCE_IMPORT_START"))
	try
		tell application id "com.apple.iWork.Keynote"
			activate
			tell front document
				tell «class crsl»
					if shouldCreateNewImage is true then
						set newImageItem to make new «class imag» with properties {file:exportedImageFile}
						set «class dscr» of newImageItem to imageDescription
					else
						set «class atfn» of targetImageRef to exportedImageFile
						set «class dscr» of targetImageRef to imageDescription
					end if
				end tell
			end tell
		end tell
		
		-- MOVE EXPORT FOLDER TO TRASH
		set fileManager to current application's NSFileManager's defaultManager()
		set thisPOSIXPath to the POSIX path of exportedImageFile
		set thisPOSIXPath to current application's NSString's stringWithString:thisPOSIXPath
		set pathOfFolderToDelete to thisPOSIXPath's stringByDeletingLastPathComponent()
		set resultingURL to missing value
		set URLOfItemToTrash to (current application's |NSURL|'s fileURLWithPath:pathOfFolderToDelete)
		(fileManager's trashItemAtURL:URLOfItemToTrash resultingItemURL:resultingURL |error|:(missing value))
		
		announceCompletion()
		
		-- store the JXA call to this handler
		set JXACommandString to "Library('DC-Photos').exportSelectedPhotosImageIntoCurrentKeynoteImage();"
		tell script "DC-Support" to storeJXACommandString(JXACommandString)
	on error errorMessage number errorNumber
		if errorNumber is not -128 then
			my displaySpokenErrorAlert(errorMessage, "com.apple.iWork.Keynote")
		end if
		error number -128
	end try
end exportSelectedPhotosImageIntoCurrentKeynoteImage

on newBlankSlide(thisDocument)
	tell application id "com.apple.iWork.Keynote"
		if thisDocument is missing value or thisDocument is "" then
			set thisDocument to the front document
		end if
		-- add a new blank slide after title slide
		tell thisDocument
			set theseMasterSlideNames to the name of every «class KnMs»
			if theseMasterSlideNames contains "Blank" then
				set shouldUseBlankMaster to true
			else
				set shouldUseBlankMaster to false
			end if
			if shouldUseBlankMaster is true then
				set thisSlide to make new «class KnSd» with properties {«class smas»:«class KnMs» "Blank"}
			else
				set thisSlide to make new «class KnSd»
				-- clear the slide of items
				set «class pLck» of every «class fmti» of thisSlide to false
				delete every «class fmti» of thisSlide
			end if
			return thisSlide
		end tell
	end tell
end newBlankSlide

(* EXPORT HANDLERS *)

on getSelectedMediaItems()
	tell application id "com.apple.Photos"
		set theseMediaItems to (get selection)
		if theseMediaItems is {} then
			my displaySpokenErrorAlert("NO_ITEMS_SELECTED_IN_PHOTOS", "com.apple.Photos")
			error number -128
		else
			return theseMediaItems
		end if
	end tell
end getSelectedMediaItems

on quickExportSelectedPhotosWithReveal()
	tell application id "com.apple.Photos"
		set theseMediaItems to my getSelectedMediaItems()
		set namingMethodIndicator to 1 -- current file names
		set shouldExportOriginals to false
		set baseName to ""
		set thisSeparator to ""
		set thisDigitLength to 3
		set startingNumber to 1
		set shouldRevealInFinder to true
		set shouldReturnFileRefs to true
		my quickExport(theseMediaItems, shouldReturnFileRefs, shouldRevealInFinder, namingMethodIndicator, shouldExportOriginals, baseName, thisSeparator, thisDigitLength, startingNumber)
	end tell
	announceCompletion()
end quickExportSelectedPhotosWithReveal

on quickExportSelectedPhotosWithoutReveal()
	tell application id "com.apple.Photos"
		set theseMediaItems to my getSelectedMediaItems()
		set namingMethodIndicator to 1 -- current file names
		set shouldExportOriginals to false
		set baseName to ""
		set thisSeparator to ""
		set thisDigitLength to 3
		set startingNumber to 1
		set shouldRevealInFinder to false
		set shouldReturnFileRefs to true
		set exportedFiles to (my quickExport(theseMediaItems, shouldReturnFileRefs, shouldRevealInFinder, namingMethodIndicator, shouldExportOriginals, baseName, thisSeparator, thisDigitLength, startingNumber))
		return exportedFiles
	end tell
	-- announceCompletion()
end quickExportSelectedPhotosWithoutReveal

on quickExportSelectedPhotosAsSequence()
	tell application id "com.apple.Photos"
		set theseMediaItems to my getSelectedMediaItems()
		set userProvidedName to my askForText("IMAGE_SEQUENCE_BASENAME_PROMPT", "CONFIRMATION_BUTTON_TITLE", "CANCEL_BUTTON_TITLE", "", "com.apple.Photos")
		if userProvidedName is "" then
			set userProvidedName to my getLocalizedStringForKey("DEFAULT_BASE_NAME")
		end if
		set namingMethodIndicator to 0 -- sequence naming
		set shouldExportOriginals to false
		set baseName to my replaceStringInString(userProvidedName, ":", "-")
		set thisSeparator to "-"
		set thisDigitLength to the length of ((count of theseMediaItems) as text)
		set startingNumber to 1
		set shouldRevealInFinder to true
		set shouldReturnFileRefs to true
		my quickExport(theseMediaItems, shouldReturnFileRefs, shouldRevealInFinder, namingMethodIndicator, shouldExportOriginals, baseName, thisSeparator, thisDigitLength, startingNumber)
	end tell
	announceCompletion()
end quickExportSelectedPhotosAsSequence

on quickExport(theseItems, returnFileReferencesBoolean, revealIndicatorBoolean, namingMethodIndicator, shouldExportOriginals, baseName, thisSeparator, thisDigitLength, startingNumber)
	set exportFolder to my createExportFolder()
	set exportFolderPOSIXPath to POSIX path of exportFolder
	if namingMethodIndicator is 2 then -- name exported items to their Photos ID
		set fileManager to current application's NSFileManager's defaultManager()
		repeat with i from 1 to the count of theseItems
			tell application id "com.apple.Photos"
				set thisItem to item i of theseItems
				set thisID to id of thisItem
				set currentName to filename of thisItem
				export {thisItem} to exportFolder without using originals
			end tell
			set thisItemName to (current application's NSString's stringWithString:currentName)
			set nameWithoutExtension to (thisItemName's stringByDeletingPathExtension()) as string
			set targetFileName to nameWithoutExtension & ".jpg"
			set newName to thisID & ".jpg"
			-- use File Manager to rename exported item
			set currentFilePath to exportFolderPOSIXPath & targetFileName
			set newFilePath to exportFolderPOSIXPath & newName
			(fileManager's moveItemAtPath:currentFilePath toPath:newFilePath |error|:(missing value))
		end repeat
	else if namingMethodIndicator is 1 then -- current file names. Option to export originals
		tell application id "com.apple.Photos"
			export theseItems to exportFolder using originals shouldExportOriginals
		end tell
	else if namingMethodIndicator is 0 then -- sequential naming
		set fileManager to current application's NSFileManager's defaultManager()
		set thisIndex to startingNumber
		repeat with i from 1 to the count of theseItems
			tell application id "com.apple.Photos"
				set thisItem to item i of theseItems
				set currentName to filename of thisItem
				export {thisItem} to exportFolder without using originals
			end tell
			-- determine new name for exported file
			set thisItemName to (current application's NSString's stringWithString:currentName)
			set nameWithoutExtension to (thisItemName's stringByDeletingPathExtension()) as string
			set targetFileName to nameWithoutExtension & ".jpg"
			set newName to my createNumericName(baseName, thisSeparator, thisDigitLength, thisIndex, "jpg")
			-- use File Manager to rename exported item
			set currentFilePath to exportFolderPOSIXPath & targetFileName
			set newFilePath to exportFolderPOSIXPath & newName
			(fileManager's moveItemAtPath:currentFilePath toPath:newFilePath |error|:(missing value))
			-- increment counter
			set thisIndex to thisIndex + 1
		end repeat
	end if
	if returnFileReferencesBoolean is true then
		-- RETRIEVE REFERENCES TO EXPORTED ITEMS AND SORT BY CREATION DATE OR NAME
		set folderPosixPath to POSIX path of exportFolder
		if namingMethodIndicator is in {0, 1} then
			-- SORT BY NAME
			set resultingReferences to sortedListOfItemsIn(folderPosixPath, 0)
		else -- SORT BY DATE
			set resultingReferences to sortedListOfItemsIn(folderPosixPath, 1)
		end if
	else
		set resultingReferences to exportFolder
	end if
	if revealIndicatorBoolean is true then
		revealInFinder(resultingReferences)
	end if
	return resultingReferences
end quickExport

on sortedListOfItemsIn(folderPosixPath, sortKeyIndicator)
	set theNSURL to current application's class "NSURL"'s fileURLWithPath:folderPosixPath -- make URL for folder because that's what's needed
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

on revealInFinder(theseItems)
	-- convert passed file refs to POSIX paths and then to file URLs
	if the class of theseItems is not list then set theseItems to theseItems as list
	set theseURLs to {}
	repeat with i from 1 to the count of theseItems
		set thisItem to item i of theseItems
		set thisItemPOSIXPath to the POSIX path of thisItem
		set the end of theseURLs to (current application's NSURL's fileURLWithPath:thisItemPOSIXPath)
	end repeat
	-- reveal items in file viewer
	tell current application's NSWorkspace to set theWorkspace to sharedWorkspace()
	tell theWorkspace to activateFileViewerSelectingURLs:theseURLs
end revealInFinder

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

(*
on createExportFolder()
	-- generate new folder in Pictures folder
	set fileManager to current application's NSFileManager's defaultManager()
	set theURL to (fileManager's URLsForDirectory:(current application's NSPicturesDirectory) inDomains:(current application's NSUserDomainMask))'s firstObject()
	--set picturesFolderPOSIXPath to the POSIX path of (path to pictures folder)
	set picturesFolderPOSIXPath to the POSIX path of (theURL as string)
	
	set targetPath to picturesFolderPOSIXPath & generateExportFolderName()
	--set fileManager to current application's NSFileManager's defaultManager()
	repeat
		set theResult to fileManager's createDirectoryAtPath:targetPath withIntermediateDirectories:false attributes:(missing value) |error|:(missing value)
		if (theResult as integer = 1) is true then
			return (targetPath as POSIX file as alias)
		else
			set targetPath to picturesFolderPOSIXPath & generateExportFolderName()
		end if
	end repeat
end createExportFolder
*)

on createExportFolder()
	-- generate new folder in Pictures folder
	set picturesFolderPOSIXPath to the POSIX path of (path to pictures folder)
	-- generate a date/time-based folder name using the formatting of the current locale
	set targetPath to picturesFolderPOSIXPath & generateTempFolderName(false)
	set fileManager to current application's NSFileManager's defaultManager()
	set theResult to (fileManager's createDirectoryAtPath:targetPath withIntermediateDirectories:false attributes:(missing value) |error|:(missing value)) as boolean
	if (theResult is false) then -- there was a problem creating the directory because of localization
		-- generate a date/time-based folder name using an indicated format
		set targetPath to picturesFolderPOSIXPath & generateTempFolderName(true)
		-- create the directory
		set theResult to (fileManager's createDirectoryAtPath:targetPath withIntermediateDirectories:false attributes:(missing value) |error|:(missing value)) as boolean
		if theResult is true then
			return (targetPath as POSIX file as alias)
		else
			error "There was a problem creating output folder."
		end if
	else
		return (targetPath as POSIX file as alias)
	end if
end createExportFolder

on createNumericName(baseName, numericSuffixSeparator, minimumNumericLength, thisIndex, thisFileExtension)
	-- add leading zeros if indicated and necessary
	if minimumNumericLength is 0 then
		set thisIncrementString to thisIndex
	else
		set numberOfLeadingZeros to minimumNumericLength - (length of (thisIndex as text))
		set thisIncrementString to thisIndex
		if numberOfLeadingZeros is greater than or equal to 1 then
			repeat numberOfLeadingZeros times
				set thisIncrementString to "0" & thisIncrementString
			end repeat
		end if
	end if
	set newName to (baseName & numericSuffixSeparator & thisIncrementString & "." & thisFileExtension) as string
	return newName
end createNumericName

(*
on generateExportFolderName()
	-- GET THE LOCALIZATION STRING FOR THE EXPORT FOLDER NAME
	set localizedDateStringForFolderName to (my getLocalizedStringForKey("EXPORT_FOLDER_NAME"))
	--set localizedDateStringForFolderName to "Photos Export %1$@ at %2$@"
	-- convert to Cocoa string
	set localizedStringObject to current application's NSString's stringWithString:localizedDateStringForFolderName
	-- GET THE CURRENT DATE
	set targetDate to current application's NSDate's |date|()
	-- CREATE A NEW DATE FORMATTER
	set dateFormatter to current application's NSDateFormatter's alloc()'s init()
	-- SET FORMTTER TO DATE STRING FORMAT
	dateFormatter's setDateFormat:"yyyy-MM-dd"
	-- GENERATE THE DATE STRING
	set currentDateString to (dateFormatter's stringFromDate:targetDate)
	--> "2015-07-15"
	-- SET FORMATTER TO TIME STRING FORMAT
	dateFormatter's setDateFormat:"HH:mm:ss a"
	-- GENERATE THE TIME STRING
	set currentTimeString to (dateFormatter's stringFromDate:targetDate)
	--> "18:18:32 PM"
	-- REPLACE PLACEHOLDER VARIABLES WITH GENERATED FILE-SYSTEM COMPLIANT DATE AND TIME STRINGS
	set localizedStringObject to (localizedStringObject's stringByReplacingOccurrencesOfString:"%1$@" withString:currentDateString)
	set localizedStringObject to (localizedStringObject's stringByReplacingOccurrencesOfString:"%2$@" withString:currentTimeString)
	--> "Photos Export 2015-07-15 at 18:37:23 PM"
	set folderName to localizedStringObject's stringByReplacingOccurrencesOfString:":" withString:"."
	--> "Photos Export 2015-07-15 at 18.37.23 PM"
	-- RETURN THE FOLDER NAME
	return (folderName as string)
	--> "Photos Export 2015-07-15 at 18.37.23 PM"
end generateExportFolderName
*)

on generateTempFolderName(localDateFormatterTest)
	-- GET THE LOCALIZATION STRING FOR THE EXPORT FOLDER NAME
	set localizedDateStringForFolderName to (my getLocalizedStringForKey("EXPORT_FOLDER_NAME"))
	
	-- CONVERT TO COCOA STRING
	set localizedStringObject to current application's NSString's stringWithString:localizedDateStringForFolderName
	
	-- GET THE CURRENT DATE
	set targetDate to current application's NSDate's |date|()
	
	-- GET THE CURRENT LOCALE
	set localeObject to current application's NSLocale's currentLocale()
	
	-- CREATE A NEW DATE FORMATTER
	set dateFormatter to current application's NSDateFormatter's alloc()'s init()
	dateFormatter's setLocale:localeObject
	dateFormatter's setDateStyle:(current application's NSDateFormatterShortStyle)
	dateFormatter's setTimeStyle:(current application's NSDateFormatterMediumStyle)
	set myFormat to dateFormatter's dateFormat as string
	
	-- SET THE FORMAT WHEN THE PATH IS INCORRECT
	if localDateFormatterTest is true then
		dateFormatter's setDateFormat:"yyyy-MM-dd HH:mm:ss a"
	end if
	
	-- GENERATE THE DATE STRING
	set currentDateString to (dateFormatter's stringFromDate:targetDate)
	
	-- REPLACE PLACEHOLDER VARIABLES WITH GENERATED FILE-SYSTEM COMPLIANT DATE AND TIME STRINGS
	set localizedStringObject to (localizedStringObject's stringByReplacingOccurrencesOfString:"%1$@" withString:currentDateString)
	--> "Photos Export 2015-07-15 at 18:37:23 PM"
	set folderName to localizedStringObject's stringByReplacingOccurrencesOfString:":" withString:"."
	--> "Photos Export 2015-07-15 at 18.37.23 PM"
	-- RETURN THE FOLDER NAME
	return (folderName as string)
	--> "Photos Export 2015-07-15 at 18.37.23 PM"
end generateTempFolderName

on addImageFileToSlide(thisDocument, thisSlide, thisImageFile, scaleToFill, shouldUseDescriptionForNotes)
	tell application "Keynote Creator Studio"
		try
			if thisDocument is missing value or thisDocument is "" then
				set thisDocument to the front document
			end if
			activate
			set queryResult to my getImageDimensions(POSIX path of thisImageFile)
			if queryResult is false then
				error number 10000
			else
				copy queryResult to {imageWidth, imageHeight}
			end if
			tell thisDocument
				set documentWidth to its width
				set documentHeight to its height
			end tell
			tell thisSlide
				if scaleToFill is false then
					set thisImage to make new image with properties {file:thisImageFile}
					tell thisImage
						set thisImageWidth to its width
						set thisImageHeight to its height
						-- center image
						set position of it to ¬
							{(documentWidth - thisImageWidth) / 2 ¬
								, (documentHeight - thisImageHeight) / 2}
					end tell
				else -- scale to fill
					-- figure new image height based on setting new image width to slide width
					set newImageHeight to (imageHeight * documentWidth) / imageWidth
					-- check to see if new image height is greater than or equal to document height
					if newImageHeight is greater than or equal to documentHeight then
						set newImageWidth to documentWidth
						-- center image vertically
						set verticalOffset to ((newImageHeight - documentHeight) / 2) * -1
						set horizontalOffset to 0
					else
						-- scale image height to match slide height
						set newImageHeight to documentHeight
						set newImageWidth to (documentHeight * imageWidth) / imageHeight
						-- center image horizontally
						set verticalOffset to 0
						set horizontalOffset to ((newImageWidth - documentWidth) / 2) * -1
					end if
					-- import, scale, and position image
					set thisImage to make new image with properties ¬
						{file:thisImageFile ¬
							, width:newImageWidth ¬
							, height:newImageHeight ¬
							, position:{horizontalOffset, verticalOffset}}
				end if
				-- get image description
				set thisDescription to my getkMDItemDescriptionFromImageFile(thisImageFile)
				log thisDescription
				if thisDescription is "" then -- if no description, use the image title
					set thisDescription to my getkMDItemTitleFromImageFile(thisImageFile)
				end if
				log thisDescription
				set description of thisImage to thisDescription
				if shouldUseDescriptionForNotes is true then
					set presenter notes of it to thisDescription
				end if
			end tell
		on error errorMessage number errorNumber
			if errorNumber is not -128 then
				display alert errorNumber message errorMessage
			end if
			error number -128
		end try
	end tell
end addImageFileToSlide

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

on promptForAndWriteImageTitles()
	try
		tell application id "com.apple.Photos"
			activate
			set theseItems to (get selection)
			if theseItems is {} then
				my displaySpokenErrorAlert("NO_ITEMS_SELECTED_IN_PHOTOS", "com.apple.Photos")
				error number -128
			end if
			set itemCount to the count of theseItems
			set firstPrompt to my getLocalizedStringForKey("TITLE_PROMPT_FIRST_IMAGE")
			set repeatingPrompt to my getLocalizedStringForKey("WORD_FOR_OF")
			set dialogPrompt to my getLocalizedStringForKey("TITLING_DIALOG_PROMPT")
			set cancelButtonTitle to my getLocalizedStringForKey("CANCEL_BUTTON_TITLE")
			set skipButtonTitle to my getLocalizedStringForKey("SKIP_BUTTON_TITLE")
			set enterButtonTitle to my getLocalizedStringForKey("ENTER_BUTTON_TITLE")
			repeat with i from 1 to the itemCount
				set thisItem to item i of theseItems
				set itemName to name of thisItem
				if itemName is missing value or itemName is "" then
					set itemName to filename of thisItem
				end if
				spotlight thisItem
				delay 0.5
				if i is 1 then
					say (firstPrompt & itemCount) without waiting until completion
				else
					say ((i as string) & space & repeatingPrompt & space & itemCount) without waiting until completion
				end if
				display dialog dialogPrompt & itemName & tab & "(" & (i as string) & "/" & (itemCount as string) & ")" default answer itemName buttons {cancelButtonTitle, skipButtonTitle, enterButtonTitle} default button 3
				copy result to {text returned:enteredName, button returned:buttonPressed}
				if buttonPressed is enterButtonTitle then
					set enteredName to my trimWhiteSpaceAroundString(enteredName)
					if enteredName is not itemName then
						set name of thisItem to enteredName
					end if
				else if buttonPressed is cancelButtonTitle then
					error number -128
				end if
			end repeat
		end tell
		tell application "System Events" to keystroke space
		say (my getLocalizedStringForKey("SUCCESSFUL_COMPLETION_PHRASE"))
	on error errorMessage number errorNumber
		if errorNumber is -128 then
			-- do nothing
			say (my getLocalizedStringForKey("WORD_FOR_STOPPING"))
			-- tell application "System Events" to keystroke space
			error number -128
		else
			display alert (errorNumber as string) message errorMessage
			error number -128
		end if
	end try
end promptForAndWriteImageTitles

on promptForAndWriteImageDescriptions()
	try
		tell application id "com.apple.Photos"
			activate
			set theseItems to (get selection)
			if theseItems is {} then
				my displaySpokenErrorAlert("NO_ITEMS_SELECTED_IN_PHOTOS", "com.apple.Photos")
				error number -128
			end if
			set itemCount to the count of theseItems
			set firstPrompt to my getLocalizedStringForKey("DESCRIPTION_PROMPT_FIRST_IMAGE")
			set repeatingPrompt to my getLocalizedStringForKey("WORD_FOR_OF")
			set dialogPrompt to my getLocalizedStringForKey("DESCRIPTION_DIALOG_PROMPT")
			set cancelButtonTitle to my getLocalizedStringForKey("CANCEL_BUTTON_TITLE")
			set skipButtonTitle to my getLocalizedStringForKey("SKIP_BUTTON_TITLE")
			set enterButtonTitle to my getLocalizedStringForKey("ENTER_BUTTON_TITLE")
			repeat with i from 1 to the itemCount
				set thisItem to item i of theseItems
				set itemName to name of thisItem
				if itemName is missing value or itemName is "" then
					set itemName to filename of thisItem
				end if
				set currentDescription to description of thisItem
				if currentDescription is missing value then set currentDescription to linefeed & linefeed & linefeed & return
				spotlight thisItem
				delay 0.5
				if i is 1 then
					say (firstPrompt & itemCount) without waiting until completion
				else
					say ((i as string) & space & repeatingPrompt & space & itemCount) without waiting until completion
				end if
				display dialog dialogPrompt & itemName & tab & "(" & (i as string) & "/" & (itemCount as string) & ")" default answer currentDescription buttons {cancelButtonTitle, skipButtonTitle, enterButtonTitle} default button 3
				copy result to {text returned:thisDescription, button returned:buttonPressed}
				if buttonPressed is enterButtonTitle then
					set thisDescription to my trimWhiteSpaceAroundString(thisDescription)
					set description of thisItem to thisDescription
				else if buttonPressed is cancelButtonTitle then
					error number -128
				end if
			end repeat
		end tell
		tell application "System Events" to keystroke space
		say (my getLocalizedStringForKey("SUCCESSFUL_COMPLETION_PHRASE"))
	on error errorMessage number errorNumber
		if errorNumber is -128 then
			-- do nothing
			say (my getLocalizedStringForKey("WORD_FOR_STOPPING"))
			tell application "System Events" to keystroke space
			error number -128
		else
			display alert (errorNumber as string) message errorMessage
			error number -128
		end if
	end try
end promptForAndWriteImageDescriptions

on trimWhiteSpaceAroundString(thisString)
	set theString to current application's NSString's stringWithString:thisString
	set theWhiteSet to current application's NSCharacterSet's whitespaceAndNewlineCharacterSet()
	set theString to theString's stringByTrimmingCharactersInSet:theWhiteSet
	return theString as text
end trimWhiteSpaceAroundString

on clearTitlesAndDescriptionsFromSelectedItems()
	tell current application
		set renameConfirmationString to my getLocalizedStringForKey("CONFIRMATION_FOR_DELETE_TITLE_DESCRIPTIONS")
		set cancelButtonTitle to my getLocalizedStringForKey("CANCEL_BUTTON_TITLE")
		set confirmationButtonTitle to my getLocalizedStringForKey("CONFIRMATION_BUTTON_TITLE")
		set completionString to my getLocalizedStringForKey("COMPLETION_STRING")
		set noSelectionString to my getLocalizedStringForKey("PLEASE_SELECT_PHOTOS_STRING")
	end tell
	tell application id "com.apple.Photos"
		activate
		set theseItems to (get selection)
		if theseItems is {} then
			say noSelectionString
			error number -128
		end if
		
		say renameConfirmationString without waiting until completion
		display dialog renameConfirmationString buttons {cancelButtonTitle, confirmationButtonTitle} default button 1 with icon 1
		repeat with i from 1 to the count of theseItems
			set thisItem to item i of theseItems
			set name of thisItem to ""
			set description of thisItem to ""
		end repeat
		say completionString
	end tell
end clearTitlesAndDescriptionsFromSelectedItems

(* COPYRIGHT *)

on exportSelectedPhotosWithOverlaidCopyright(textOverlayColorIndicator)
	set copyrightString to retrievePhotosExportCopyrightString()
	if copyrightString is false then
		set copyrightString to promptForInitialExportCopyrightString()
	end if
	say (getLocalizedStringForKey("BEGIN_EXPORT_MESSAGE"))
	set exportedImageFiles to quickExportSelectedPhotosWithoutReveal()
	set newFiles to {}
	say (getLocalizedStringForKey("BEGIN_COPYRIGHT_OVERLAY_MESSAGE"))
	repeat with i from 1 to the count of exportedImageFiles
		set aFileRef to item i of exportedImageFiles
		set aPOSIXRef to the POSIX path of aFileRef
		set aTargetPOSIXRef to (text 1 thru -5 of aPOSIXRef) & "_©.jpg"
		if (generateOverlaidImageWithText(aPOSIXRef, aTargetPOSIXRef, copyrightString, textOverlayColorIndicator, 24, 0)) is true then
			set the end of newFiles to aTargetPOSIXRef
		end if
	end repeat
	if newFiles is {} then
		-- ERROR
	else
		revealInFinder(newFiles)
		announceCompletion()
	end if
end exportSelectedPhotosWithOverlaidCopyright

on promptForInitialExportCopyrightString()
	set okButtonTitle to getLocalizedStringForKey("OK_BUTTON_TITLE")
	set inputDialogPrompt to getLocalizedStringForKey("EXPORT_COPYRIGHT_STRING_INITIAL_PROMPT")
	set copyrightString to retrievePhotosExportCopyrightString()
	if copyrightString is false then set copyrightString to ""
	tell script "DC-Support"
		set copyrightString to promptForInput(inputDialogPrompt & ":", inputDialogPrompt, copyrightString, true, "OK", "com.apple.Photos")
	end tell
	storePhotosExportCopyrightString(copyrightString)
	return copyrightString
end promptForInitialExportCopyrightString

on promptForExportCopyrightString()
	setOKButtonTitle to getLocalizedStringForKey("OK_BUTTON_TITLE")
	set inputDialogPrompt to getLocalizedStringForKey("EXPORT_COPYRIGHT_STRING_PROMPT")
	set copyrightString to retrievePhotosExportCopyrightString()
	if copyrightString is false then set copyrightString to ""
	tell script "DC-Support"
		set copyrightString to promptForInput(inputDialogPrompt & ":", inputDialogPrompt, copyrightString, true, "OK", "com.apple.Photos")
	end tell
	storePhotosExportCopyrightString(copyrightString)
	return copyrightString
end promptForExportCopyrightString

on storePhotosExportCopyrightString(copyrightString)
	set prefsFolderPath to the POSIX path of (path to preferences folder from user domain)
	set targetPrefsFilePath to prefsFolderPath & "com.apple.DictationCommands.Photos.exportCopyright.plist"
	set aRecord to recordFromLabelsAndValues({"exportCopyright"}, {copyrightString})
	its storeRecord:aRecord inPath:targetPrefsFilePath
	return result
end storePhotosExportCopyrightString

on retrievePhotosExportCopyrightString()
	try
		set prefsFolderPath to the POSIX path of (path to preferences folder from user domain)
		set targetPrefsFilePath to prefsFolderPath & "com.apple.DictationCommands.Photos.exportCopyright.plist"
		tell script "DC-Workspace"
			set existenceStatus to checkForItemExistence(targetPrefsFilePath)
		end tell
		if existenceStatus is false then
			return false
		else
			set aDict to current application's NSDictionary's dictionaryWithContentsOfFile:targetPrefsFilePath
			set exportCopyright to (aDict's valueForKey:"exportCopyright") as text
			return exportCopyright
		end if
	on error errorMessage
		current application's NSLog("%@", errorMessage)
	end try
end retrievePhotosExportCopyrightString

on recordFromLabelsAndValues(theseLabels, theseValues)
	set theResult to current application's NSDictionary's dictionaryWithObjects:theseValues forKeys:theseLabels
	return theResult as record
end recordFromLabelsAndValues

on storeRecord:theRecord inPath:thePath
	set theData to current application's NSPropertyListSerialization's dataWithPropertyList:theRecord format:(current application's NSPropertyListXMLFormat_v1_0) options:0 |error|:(missing value)
	theData's writeToFile:thePath atomically:true
end storeRecord:inPath:

on generateOverlaidImageWithText(backgroundImageFilePath, outputImagePath, deviceName, textOverlayColorIndicator, fontSize, overlayBerticalPosiion)
	
	set theBackgroundImage to current application's NSImage's alloc()'s initByReferencingFile:backgroundImageFilePath
	
	-- Get Background Image dimensions
	set {width:bgndWidth, height:bgndHeight} to theBackgroundImage's |size|()
	
	-- Create a new NSImageView to overlay text
	set frame to {{0, 0}, theBackgroundImage's |size|()}
	set targetView to current application's NSImageView's alloc()'s initWithFrame:frame
	set targetView's image to theBackgroundImage
	
	-- Create a NSTextView to contain the text
	if overlayBerticalPosiion is 0 then
		set textViewY to bgndHeight div 10 -- just above the bottom
	else
		set textViewY to bgndHeight - (bgndHeight div 10) -- just below the top
	end if
	
	set textViewFrame to {{0, textViewY}, {bgndWidth, fontSize}}
	--        set textViewFrame to {{0, 0}, {targetView's extent()'s |size|'s width, fontSize}}
	
	-- magic font size formula?????
	set bgndWidth to bgndWidth as integer
	set bgndHeight to bgndHeight as integer
	set fontSize to (bgndWidth * bgndHeight) div (bgndWidth + bgndHeight) div 20
	set textView to current application's NSTextView's alloc()'s initWithFrame:textViewFrame
	set textView's |font| to current application's NSFont's systemFontOfSize:fontSize
	
	if textOverlayColorIndicator is 0 then
		set textOverlayColor to current application's NSColor's blackColor
	else
		set textOverlayColor to current application's NSColor's whiteColor
	end if
	set textView's textColor to textOverlayColor
	
	set textView's |string| to deviceName
	
	set textView's alignment to 2 -- current application's NSTextAlignmentCenter 0=left, 1=right, 2=center
	
	targetView's addSubview:textView
	
	set finalImage to current application's NSImage's alloc()'s initWithData:(targetView's dataWithPDFInsideRect:(targetView's |bounds|))
	
	-- Render file
	set tiffData to finalImage's TIFFRepresentation()
	set imageRep to current application's NSBitmapImageRep's imageRepWithData:tiffData
	set theProps to current application's NSDictionary's dictionaryWithObject:1.0 forKey:(current application's NSImageCompressionFactor)
	--set imageData to (imageRep's representationUsingType:(current application's NSPNGFileType) |properties|:theProps)
	set imageData to (imageRep's representationUsingType:(current application's NSJPEGFileType) |properties|:theProps)
	set theResult to (imageData's writeToFile:outputImagePath atomically:true |error|:(missing value)) as boolean
end generateOverlaidImageWithText

(* TITLE & DESCRIPTION PALETTE *)
on launchTitleDescriptionApplet()
	set libraryPath to the POSIX path of (path to me)
	set helperAppletPath to libraryPath & "Contents/Resources/Photos Description Helper.app"
	do shell script "open " & quoted form of helperAppletPath
end launchTitleDescriptionApplet

(* SLIDESHOW *)

on beginSlideshowUsingSelection()
	try
		tell application id "com.apple.Photos"
			activate
			if slideshow running is false then stop slideshow
			set theseItems to (get selection)
			if theseItems is {} then
				error "NO_ITEMS_SELECTED_IN_PHOTOS"
			end if
			start slideshow using theseItems
		end tell
	on error errorMessage number errorNumber
		my displaySpokenErrorAlert(errorMessage, "com.apple.Photos")
	end try
end beginSlideshowUsingSelection

on beginSlideshowUsingFavorites()
	try
		tell application id "com.apple.Photos"
			activate
			if slideshow running is false then stop slideshow
			start slideshow using (every media item of favorites album)
		end tell
	on error errorMessage number errorNumber
		my displaySpokenErrorAlert(errorMessage, "com.apple.Photos")
	end try
end beginSlideshowUsingFavorites

on beginSlideshowUsingLastImport()
	try
		tell application id "com.apple.Photos"
			activate
			if slideshow running is false then stop slideshow
			start slideshow using (every media item of last import album)
		end tell
	on error errorMessage number errorNumber
		my displaySpokenErrorAlert(errorMessage, "com.apple.Photos")
	end try
end beginSlideshowUsingLastImport

on stopRunningSlideshow()
	try
		tell application id "com.apple.Photos"
			activate
			if slideshow running is false then
				beep
			else
				stop slideshow
			end if
		end tell
	on error errorMessage number errorNumber
		my displaySpokenErrorAlert(errorMessage, "com.apple.Photos")
	end try
end stopRunningSlideshow

on pauseRunningSlideshow()
	try
		tell application id "com.apple.Photos"
			activate
			if slideshow running is false then
				beep
			else
				pause slideshow
			end if
		end tell
	on error errorMessage number errorNumber
		my displaySpokenErrorAlert(errorMessage, "com.apple.Photos")
	end try
end pauseRunningSlideshow

on resumeRunningSlideshow()
	try
		tell application id "com.apple.Photos"
			activate
			if slideshow running is false then
				beep
			else
				resume slideshow
			end if
		end tell
	on error errorMessage number errorNumber
		my displaySpokenErrorAlert(errorMessage, "com.apple.Photos")
	end try
end resumeRunningSlideshow

on nextSlideOfRunningSlideshow()
	try
		tell application id "com.apple.Photos"
			activate
			if slideshow running is false then
				beep
			else
				next slide
			end if
		end tell
	on error errorMessage number errorNumber
		my displaySpokenErrorAlert(errorMessage, "com.apple.Photos")
	end try
end nextSlideOfRunningSlideshow

on previousSlideOfRunningSlideshow()
	try
		tell application id "com.apple.Photos"
			activate
			if slideshow running is false then
				beep
			else
				previous slide
			end if
		end tell
	on error errorMessage number errorNumber
		my displaySpokenErrorAlert(errorMessage, "com.apple.Photos")
	end try
end previousSlideOfRunningSlideshow



(* SUPPORT HANDLERS *)

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
		set cfgutil to "/usr/bin/say"
		set theTask to (current application's NSTask's launchedTaskWithLaunchPath:cfgutil arguments:{errorMessage})
		set cancelButtonTitle to getLocalizedStringForKey("CANCEL_BUTTON_TITLE")
		tell application id appID
			activate
			display alert errorTitle message errorMessage buttons {cancelButtonTitle}
		end tell
		-- stop speaking
		theTask's terminate()
		return true
	on error errorMessage
		log errorMessage
		-- stop speaking
		theTask's terminate()
		return false
	end try
end displaySpokenErrorAlert

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

on askForText(messageKey, approveButtonKey, disapproveButtonKey, defaultText, appID)
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
			display dialog confirmationMessage buttons {disapprovalButtonTitle, approvalButtonTitle} default button 2 with title confirmationTitle default answer defaultText
			copy result to {button returned:userChoice, text returned:userText}
		end tell
		-- stop speaking
		theTask's terminate()
		if userChoice is approvalButtonTitle then
			return userText
		else
			return false
		end if
	on error errorMessage
		log errorMessage
		-- stop speaking
		theTask's terminate()
		return false
	end try
end askForText

on announceCompletion()
	say (my getLocalizedStringForKey("SUCCESSFUL_COMPLETION_PHRASE"))
end announceCompletion

on replaceStringInString(sourceText, searchString, replacementString)
	set aString to current application's NSString's stringWithString:sourceText
	set resultString to the (aString's stringByReplacingOccurrencesOfString:searchString withString:replacementString)
	return resultString as text
end replaceStringInString

(* LOCALIZATION ROUTINE *)
on getLocalizedStringForKey(thisKey)
	set thisBundlePath to (path to me)
	return (localized string thisKey in bundle thisBundlePath)
end getLocalizedStringForKey
