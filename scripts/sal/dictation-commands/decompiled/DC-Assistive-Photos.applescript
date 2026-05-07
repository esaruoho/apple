use framework "Foundation"
use scripting additions


property silence1000 : " [[slnc 1000]] "
property silence750 : " [[slnc 750]] "
property silence500 : " [[slnc 500]] "
property silence250 : " [[slnc 250]] "

property speakingRate : 200
property wordForNoValue : "missing"
property dialogDuration : 8

property panoramaAspectRation : 3

on sayHowManyItemsAreSelected()
	tell application id "com.apple.Photos"
		activate
		set theseMediaItems to (get selection)
		set mediaItemCount to the count of theseMediaItems
	end tell
	tell current application
		say ((my convertToNoForZero(mediaItemCount)) & space & (my pluralizeThisNoun("item", mediaItemCount)) & space & (my isOrAre(mediaItemCount)) & space & "selected.") as text
	end tell
end sayHowManyItemsAreSelected

on describeAndChooseFromSelectedMediaItems()
	try
		tell application id "com.apple.Photos" to activate
		tell current application to delay 2
		
		set libraryPath to the POSIX path of (path to me)
		set helperAppletPath to libraryPath & "Contents/Resources/Photos Describe and Choose.app"
		do shell script "open " & quoted form of helperAppletPath
		
	on error errorMessage number errorNumber
		my displaySpokenErrorAlert(errorMessage, "com.apple.Photos")
		error number -128
	end try
end describeAndChooseFromSelectedMediaItems

on chooseByVoice(itemStrings)
	set itemStrings to {"Stop", "Select", "Continue"}
	set userResponse to ""
	tell application id "com.apple.speech.SpeechRecognitionServer"
		-- "/System/Library/PrivateFrameworks/SpeechObjects.framework/Versions/A/SpeechRecognitionServer.app" 
		set the userResponse to listen for itemStrings giving up after 30
		tell it to quit
	end tell
	if userResponse is "" then
		return false
	else
		return userResponse
	end if
end chooseByVoice

on stringFromList(thisList, thisDelimiterString)
	set thisArray to current application's NSArray's arrayWithArray:thisList
	set combinedItemsString to (thisArray's componentsJoinedByString:thisDelimiterString) as text
	return combinedItemsString as text
end stringFromList


on beginPhotosSearch()
	tell application id "com.apple.Photos" to activate
	tell application "System Events" to keystroke "f" using command down
	say getLocalizedStringForKey("READY_RESPONSE")
end beginPhotosSearch

on beginAlternatePhotosSearch()
	tell application id "com.apple.Photos"
		activate
		say (my getLocalizedStringForKey("READY_RESPONSE")) without waiting until completion
		display dialog "Enter search terms or phrase:" default answer "" buttons {"Cancel", "Search"} default button 2
		set thisSearchString to the text returned of the result
		if thisSearchString is "" then error number -128
	end tell
	tell application "System Events"
		tell process "Photos"
			set mainWindow to first window whose subrole is "AXStandardWindow" and description is "Photos"
			set windowToolbar to toolbar 1 of mainWindow
			set theseElements to the entire contents of windowToolbar
			set searchField to missing value
			keystroke "f" using command down
			delay 1
			repeat with i from 1 to the count of theseElements
				set thisElement to item i of theseElements
				if the class of thisElement is text field and subrole of thisElement is "AXSearchField" then
					set searchField to thisElement
					set value of searchField to thisSearchString
					delay 0.5
					try
						select searchField
					end try
					exit repeat
				end if
			end repeat
			set frontmost to true
			try
				get first window whose subrole is "AXUnknown"
			on error
				beep
				return "no results"
			end try
		end tell
		delay 2
		keystroke return
		--say "BOB"
	end tell
	announceCompletion()
end beginAlternatePhotosSearch

on cancelPhotosSearch()
	tell application id "com.apple.Photos" to activate
	tell application "System Events"
		tell process "Photos"
			set mainWindow to first window whose subrole is "AXStandardWindow" and description is "Photos"
			set windowToolbar to toolbar 1 of mainWindow
			set theseElements to the entire contents of windowToolbar
			set searchField to missing value
			repeat with i from 1 to the count of theseElements
				set thisElement to item i of theseElements
				if the class of thisElement is text field and subrole of thisElement is "AXSearchField" then
					set searchField to thisElement
					if exists button 2 of searchField then
						click button 2 of searchField
					end if
					exit repeat
				end if
			end repeat
		end tell
	end tell
end cancelPhotosSearch

on appendOrientationKeywordsToSelectedItems()
	try
		set horizontalKeyword to getLocalizedStringForKey("HORIZONTAL_KEYWORD")
		set verticalKeyword to getLocalizedStringForKey("VERTICAL_KEYWORD")
		set squareKeyword to getLocalizedStringForKey("SQUARE_KEYWORD")
		set panoramaKeyword to getLocalizedStringForKey("PANORAMA_KEYWORD")
		tell application id "com.apple.Photos"
			activate
			set theseMediaItems to (get selection)
			if theseMediaItems is {} then
				error "NO_ITEMS_SELECTED_IN_PHOTOS"
			end if
			set mediaItemCount to the count of theseMediaItems
			repeat with i from 1 to mediaItemCount
				set theseKeywords to {}
				set thisItem to item i of theseMediaItems
				set itemWidth to width of thisItem
				set itemHeight to height of thisItem
				if itemWidth is greater than itemHeight then
					set the end of theseKeywords to horizontalKeyword
					if (itemWidth div itemHeight) is greater than or equal to panoramaAspectRation then
						set the end of theseKeywords to panoramaKeyword
					end if
				else if itemHeight is greater than itemWidth then
					set the end of theseKeywords to verticalKeyword
				else if itemHeight is itemWidth then
					set the end of theseKeywords to squareKeyword
				end if
				my appendKeywords(thisItem, theseKeywords)
			end repeat
		end tell
		announceCompletion()
	on error errorMessage number errorNumber
		my displaySpokenErrorAlert(errorMessage, "com.apple.Photos")
		error number -128
	end try
end appendOrientationKeywordsToSelectedItems

on determineSizeType(itemWidth, itemHeight)
	log itemWidth
	log itemHeight
	if itemWidth is equal to itemHeight then
		set sizeType to "square"
	else if itemWidth is greater than itemHeight then
		if itemWidth div itemHeight is greater than or equal to 2 then
			set sizeType to "horizontal panorama"
		else
			set sizeType to "horizontal"
		end if
	else
		if itemHeight div itemWidth is greater than or equal to 2 then
			set sizeType to "vertical panorama"
		else
			set sizeType to "vertical"
		end if
	end if
	return sizeType
end determineSizeType

on pluralizeThisNoun(thisString, thisValue)
	if thisValue is 1 then
		return thisString
	else
		return (thisString & "s")
	end if
end pluralizeThisNoun

on isOrAre(thisValue)
	if thisValue is 1 then
		return "is"
	else
		return "are"
	end if
end isOrAre

on yesOrNo(booleanValue)
	if booleanValue is true then
		return "yes"
	else
		return "no"
	end if
end yesOrNo

on booleanAsIsIsNot(booleanValue)
	if booleanValue is true then
		return "is"
	else
		return "is not"
	end if
end booleanAsIsIsNot

(* SUPPORT HANDLERS *)

on convertToNoForZero(thisValue)
	if thisValue is 0 then
		return "no"
	else
		return thisValue
	end if
end convertToNoForZero

on determineAOrAn(thisString)
	if the first character of thisString is in {"a", "e", "i", "o", "u"} then
		return "an"
	else
		return "a"
	end if
end determineAOrAn

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

on booleanAsOnOff(booleanValue)
	if booleanValue is true then
		return "on"
	else
		return "off"
	end if
end booleanAsOnOff

on booleanAsAreAreNot(booleanValue)
	if booleanValue is true then
		return "are"
	else
		return "are not"
	end if
end booleanAsAreAreNot

on convertBooleanToShowingString(thisBooleanValue)
	if thisBooleanValue is true then
		return "is showing"
	else
		return "is not showing"
	end if
end convertBooleanToShowingString

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
			display alert errorTitle message errorMessage buttons {cancelButtonTitle} giving up after 15
		end tell
		-- stop speaking
		say " " with stopping current speech
		return true
	on error errorMessage
		log errorMessage
		error number -128
	end try
end displaySpokenErrorAlert

on spokenErrorAlert(thisMessage)
	set thisMessage to getLocalizedStringForKey(thisMessage)
	speakWithMutedInput(thisMessage)
end spokenErrorAlert

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

