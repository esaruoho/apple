use AppleScript version "2.4"
use framework "Foundation"
use framework "AppKit"
use scripting additions

(* GET CURRENT VERSION *)

on getDCDownloadVersion(shouldSpeak)
	try
		with timeout of 60 seconds
			set versionString to (do shell script "curl http://dictationcommands.com/version.txt")
		end timeout
		if shouldSpeak is true then
			set replyPrefix to getLocalizedStringForKey("DOWNLOAD_VERSION_PREFIX")
			speakWithMutedInput(replyPrefix & versionString)
		end if
		return versionString
	on error errorMessage number errorNumber
		my logThis(errorMessage)
		if errorNumber is not -128 then
			my displaySpokenErrorAlert(errorMessage, "")
		end if
		error number -128
	end try
end getDCDownloadVersion

on downloadCurrentDCArchive()
	try
		set currentVersion to getDCDownloadVersion(false)
		set downloadItemName to "CitrusPeel" & currentVersion & ".zip"
		set downloadURL to "http://dictationcommands.com/" & downloadItemName
		tell script "DC-Workspace"
			set downloadsFolderPath to getPathForUserDownloadsDirectory(false)
		end tell
		set downloadDestinationPath to downloadsFolderPath & "/" & downloadItemName
		say (getLocalizedStringForKey("DOWNLOAD_BEGIN") & currentVersion)
		do shell script "curl -o " & (quoted form of downloadDestinationPath) & space & downloadURL
		tell script "DC-Workspace"
			revealInFinder(downloadDestinationPath)
		end tell
		announceCompletion()
	on error errorMessage number errorNumber
		my logThis(errorMessage)
		if errorNumber is not -128 then
			my displaySpokenErrorAlert(errorMessage, "")
		end if
		error number -128
	end try
end downloadCurrentDCArchive

(* TAKE DICTATION *)

on takeDictation(resultsOnClipboard)
	set libraryPath to the POSIX path of (path to me)
	set thisBundle to current application's NSBundle's bundleWithPath:libraryPath
	set workflowFilePath to (thisBundle's pathForResource:"Receive Dictation" ofType:"workflow") as text
	set workflowLog to (do shell script ("automator -v ") & quoted form of workflowFilePath)
	set completionPhrase to "The Automator workflow has completed."
	set completionPhraseOffset to (offset of completionPhrase in workflowLog)
	if completionPhraseOffset is 0 then
		error number -128
	else
		set x to the length of completionPhrase
		set dictatedText to text from (completionPhraseOffset + x + 1) to -1 of workflowLog
		if resultsOnClipboard is true then
			tell current application to set the clipboard to dictatedText
		end if
		return dictatedText
	end if
end takeDictation

on displayTextEntryDialog(defaultText, resultsOnClipboard)
	set libraryPath to the POSIX path of (path to me)
	log libraryPath
	set thisBundle to current application's NSBundle's bundleWithPath:libraryPath
	set workflowFilePath to (thisBundle's pathForResource:"textentry" ofType:"workflow") as text
	log workflowFilePath
	if defaultText is "" or defaultText is missing value then
		set workflowLog to (do shell script ("automator -v ") & quoted form of workflowFilePath)
	else
		set workflowLog to (do shell script ("automator -v -D defaultText=" & (quoted form of defaultText) & space & quoted form of workflowFilePath))
	end if
	set completionPhrase to "The Automator workflow has completed."
	set completionPhraseOffset to (offset of completionPhrase in workflowLog)
	if completionPhraseOffset is 0 then
		error number -128
	else
		set x to the length of completionPhrase
		set dictatedText to text from (completionPhraseOffset + x + 1) to -1 of workflowLog
		if resultsOnClipboard is true then
			tell current application to set the clipboard to dictatedText
		end if
		return dictatedText
	end if
end displayTextEntryDialog

(* UUID *)

on generateUUID()
	set aUUID to (current application's NSUUID's UUID()'s UUIDString) as text
	return aUUID
end generateUUID


(* SPEECH PREFS *)

on setAudioDucking(booleanIndicator)
	set trueOrFalse to my returnBooleanValue(booleanIndicator)
	if trueOrFalse is true then
		set booleanString to "YES"
	else
		set booleanString to "NO"
	end if
	do shell script ("defaults write com.apple.speech.recognition.AppleSpeechRecognition.prefs DictationIMAllowAudioDucking -bool " & booleanString)
	set setResult to (do shell script "defaults read com.apple.speech.recognition.AppleSpeechRecognition.prefs DictationIMAllowAudioDucking") as integer as boolean
	if setResult is not trueOrFalse then
		current application's NSLog("%@", "PROBLEM SETTING AUDIO DUCKING")
	else
		return true
	end if
end setAudioDucking

on statusOfDictation()
	try
		set dictationStatus to (do shell script "defaults read com.apple.speech.recognition.AppleSpeechRecognition.prefs DictationIMMasterDictationEnabled") as integer as boolean
		if dictationStatus is "" then error
	on error
		set dictationStatus to false
	end try
	return dictationStatus
end statusOfDictation

on statusOfAudioDucking()
	try
		set audioMutingEnabled to (do shell script "defaults read com.apple.speech.recognition.AppleSpeechRecognition.prefs DictationIMAllowAudioDucking") as integer as boolean
		if audioMutingEnabled is "" then error
	on error
		set audioMutingEnabled to true
	end try
	return audioMutingEnabled
end statusOfAudioDucking

on statusOfRecognitionSound()
	try
		set recognitionSoundEnabled to (do shell script "defaults read com.apple.speech.recognition.AppleSpeechRecognition.prefs DictationIMPlaySoundUponRecognition") as integer as boolean
		if recognitionSoundEnabled is "" then error
	on error
		set recognitionSoundEnabled to false
	end try
	return recognitionSoundEnabled
end statusOfRecognitionSound

on statusOfEnhancedDictation()
	try
		set enhancedDictationStatus to (do shell script "defaults read com.apple.speech.recognition.AppleSpeechRecognition.prefs DictationIMUseOnlyOfflineDictation") as integer as boolean
		if enhancedDictationStatus is "" then error
	on error
		set enhancedDictationStatus to false
	end try
	return enhancedDictationStatus
end statusOfEnhancedDictation

(* DO THAT AGAIN *)

on storeJXACommandString(JXAScriptText)
	set prefsFolderPath to the POSIX path of (path to preferences folder from user domain)
	set targetPrefsFilePath to prefsFolderPath & "com.apple.DictationCommands.lastCommand.plist"
	set aRecord to recordFromLabelsAndValues({"JXAScriptText"}, {JXAScriptText})
	its storeRecord:aRecord inPath:targetPrefsFilePath
	return result
end storeJXACommandString

on retrieveExecuteJXACommandString()
	try
		set prefsFolderPath to the POSIX path of (path to preferences folder from user domain)
		set targetPrefsFilePath to prefsFolderPath & "com.apple.DictationCommands.lastCommand.plist"
		tell script "DC-Workspace"
			set existenceStatus to checkForItemExistence(targetPrefsFilePath)
		end tell
		if existenceStatus is false then
			say "no stored command"
		else
			set aDict to current application's NSDictionary's dictionaryWithContentsOfFile:targetPrefsFilePath
			set JXAScriptText to (aDict's valueForKey:"JXAScriptText") as text
			run script JXAScriptText in "JavaScript"
		end if
	on error errorMessage
		current application's NSLog("%@", errorMessage)
	end try
end retrieveExecuteJXACommandString

(* KEY COMMNADS *)

on keypressUndo()
	tell application "System Events" to keystroke "z" using command down
	set JXACommandString to "Library('DC-Support').keypressUndo();"
	storeJXACommandString(JXACommandString)
end keypressUndo

on keypressTab()
	tell application "System Events" to keystroke tab
	set JXACommandString to "Library('DC-Support').keypressTab();"
	storeJXACommandString(JXACommandString)
end keypressTab

on keypressShiftTab()
	tell application "System Events" to keystroke tab using {shift down}
	set JXACommandString to "Library('DC-Support').keypressShiftTab();"
	storeJXACommandString(JXACommandString)
end keypressShiftTab

on keypressEnter()
	tell application "System Events" to key code 76
	set JXACommandString to "Library('DC-Support').keypressEnter();"
	storeJXACommandString(JXACommandString)
end keypressEnter

on keypressEscape()
	tell application "System Events" to key code 53
	set JXACommandString to "Library('DC-Support').keypressEscape();"
	storeJXACommandString(JXACommandString)
end keypressEscape

on keypressSpace()
	tell application "System Events" to key code 49
	set JXACommandString to "Library('DC-Support').keypressSpace();"
	storeJXACommandString(JXACommandString)
end keypressSpace

on keypressReturn()
	tell application "System Events" to key code 36
	set JXACommandString to "Library('DC-Support').keypressReturn();"
	storeJXACommandString(JXACommandString)
end keypressReturn

on keypressLeftArrow()
	tell application "System Events" to key code 123
	set JXACommandString to "Library('DC-Support').keypressLeftArrow();"
	storeJXACommandString(JXACommandString)
end keypressLeftArrow

on keypressRightArrow()
	tell application "System Events" to key code 124
	set JXACommandString to "Library('DC-Support').keypressRightArrow();"
	storeJXACommandString(JXACommandString)
end keypressRightArrow

on keypressDownArrow()
	tell application "System Events" to key code 125
	set JXACommandString to "Library('DC-Support').keypressDownArrow();"
	storeJXACommandString(JXACommandString)
end keypressDownArrow

on keypressUpArrow()
	tell application "System Events" to key code 126
	set JXACommandString to "Library('DC-Support').keypressUpArrow();"
	storeJXACommandString(JXACommandString)
end keypressUpArrow

on keypressDelete()
	tell application "System Events" to key code 51
	set JXACommandString to "Library('DC-Support').keypressDelete();"
	storeJXACommandString(JXACommandString)
end keypressDelete

(* BOOLEAN HANDLERS *)

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
		my displaySpokenErrorAlert(errorMsg, "")
		error number -128
	end try
end returnBooleanValue

(* STRING HANDLERS *)

on convertToLocalizedCapitals(listOfStrings)
	set thisLocale to current application's NSLocale's currentLocale()
	repeat with i from 1 to count of listOfStrings
		set aString to (current application's NSString's stringWithString:(item i of listOfStrings))
		set item i of listOfStrings to (aString's uppercaseStringWithLocale:thisLocale) as text
	end repeat
	return listOfStrings
end convertToLocalizedCapitals

on convertNumbersToStrings(theseNumbers)
	-- if you pass in a list of numbers, you get back a list of numeric strings
	-- if you pass in a single number, you get back a single string
	if the class of theseNumbers is not list then
		set theseNumbers to theseNumbers as list
		set returnAsItem to true
	else
		set returnAsItem to false
	end if
	set theFormatter to current application's NSNumberFormatter's new()
	theFormatter's setNumberStyle:(current application's NSNumberFormatterNoStyle)
	set convertedValues to {}
	repeat with i from 1 to the count of theseNumbers
		set thisNumber to item i of theseNumbers
		set numberString to (theFormatter's stringFromNumber:thisNumber) as text
		set the end of the convertedValues to numberString
	end repeat
	if returnAsItem is true then
		return (item 1 of convertedValues)
	else
		return convertedValues
	end if
end convertNumbersToStrings

on convertNumberToDecimalString(theNumber, theNumberOfDecimalPlaces)
	set theFormatter to current application's NSNumberFormatter's alloc()'s init()
	theFormatter's setMinimumFractionDigits:theNumberOfDecimalPlaces
	theFormatter's setMaximumFractionDigits:theNumberOfDecimalPlaces
	set theFormattedNumber to theFormatter's stringFromNumber:theNumber
	return (theFormattedNumber as text)
end convertNumberToDecimalString

on convertNumberToWords(thisNumber)
	--> returns a numeric value in words, e.g: (23 = “twenty-three”) (23.75 = “twenty-three point seven five”)
	tell current application's NSNumberFormatter to set resultingText to localizedStringFromNumber_numberStyle_(thisNumber, current application's NSNumberFormatterSpellOutStyle)
	return (resultingText as text)
end convertNumberToWords

on convertNumberToCurrencyValueString(thisNumber)
	--> returns comma delimited, rounded, localized currency value, e.g.: (9128 = $9,128.00) (9978.2485 = $9,128.25)
	tell current application's NSNumberFormatter to set resultingText to localizedStringFromNumber_numberStyle_(thisNumber, current application's NSNumberFormatterCurrencyStyle)
	return (resultingText as string)
end convertNumberToCurrencyValueString

on convertNumberToPercentageValueString(thisNumber)
	--> returns comma delimited, rounded, localized percentage value, e.g.: (0.2345 = 23%) (0.2375 = 24%)
	tell current application's NSNumberFormatter to set resultingText to localizedStringFromNumber_numberStyle_(thisNumber, current application's NSNumberFormatterPercentStyle)
	return (resultingText as string)
end convertNumberToPercentageValueString

on stringFromList(thisList, thisDelimiterString)
	set thisArray to current application's NSArray's arrayWithArray:thisList
	set combinedItemsString to (thisArray's componentsJoinedByString:thisDelimiterString) as text
	return combinedItemsString as text
end stringFromList

on replaceStringInString(sourceText, searchString, replacementString)
	set aString to current application's NSString's stringWithString:sourceText
	set resultString to the (aString's stringByReplacingOccurrencesOfString:searchString withString:replacementString)
	return resultString as text
end replaceStringInString

on getItemsFromDelimitedString(thisString, thisDelimiter)
	set thisString to current application's NSString's stringWithString:thisString
	set theseStrings to thisString's componentsSeparatedByString:thisDelimiter
	theseStrings as list
end getItemsFromDelimitedString

on trimWhiteSpaceAroundString(thisString)
	set theString to current application's NSString's stringWithString:thisString
	set theWhiteSet to current application's NSCharacterSet's whitespaceAndNewlineCharacterSet()
	set theString to theString's stringByTrimmingCharactersInSet:theWhiteSet
	return theString as text
end trimWhiteSpaceAroundString

on encodeUsingPercentEncoding(sourceText)
	-- create a Cocoa string from the passed AppleScript string, by calling the NSString class method stringWithString:
	set the sourceString to current application's NSString's stringWithString:sourceText
	-- apply the indicated transformation to the Cooca string
	set the adjustedString to the sourceString's stringByAddingPercentEscapesUsingEncoding:(current application's NSUTF8StringEncoding)
	-- coerce from Cocoa string to AppleScript string
	return (adjustedString as string)
end encodeUsingPercentEncoding

on decodePercentEncoding(sourceText)
	-- create a Cocoa string from the passed AppleScript string, by calling the NSString class method stringWithString:
	set the sourceString to current application's NSString's stringWithString:sourceText
	-- apply the indicated transformation to the Cooca string
	set the adjustedString to the sourceString's stringByReplacingPercentEscapesUsingEncoding:(current application's NSUTF8StringEncoding)
	-- coerce from Cocoa string to AppleScript string
	return (adjustedString as string)
end decodePercentEncoding

on changeCaseOfText(sourceText, caseIndicator)
	-- create a Cocoa string from the passed text, by calling the NSString class method stringWithString:
	set the sourceString to current application's NSString's stringWithString:sourceText
	-- apply the indicated transformation to the Cocoa string
	if the caseIndicator is 0 then
		set the adjustedString to sourceString's uppercaseString()
	else if the caseIndicator is 1 then
		set the adjustedString to sourceString's lowercaseString()
	else
		set the adjustedString to sourceString's capitalizedString()
	end if
	-- convert from Cocoa string to AppleScript string
	return (adjustedString as string)
end changeCaseOfText

on integerValueForString(thisString)
	if the class of thisString is integer then return thisString
	set stringsForOne to my getItemsFromDelimitedString(my getLocalizedStringForKey("STRINGS_FOR_ONE"), ",") -- {"won", "one"}
	set stringsForTwo to my getItemsFromDelimitedString(my getLocalizedStringForKey("STRINGS_FOR_TWO"), ",") -- {"to", "too", "two"}
	set stringsForThree to my getItemsFromDelimitedString(my getLocalizedStringForKey("STRINGS_FOR_THREE"), ",") -- {"three"}
	set stringsForFour to my getItemsFromDelimitedString(my getLocalizedStringForKey("STRINGS_FOR_FOUR"), ",") -- {"for", "four"}
	set stringsForFive to my getItemsFromDelimitedString(my getLocalizedStringForKey("STRINGS_FOR_FIVE"), ",") -- {"five"}
	set stringsForSix to my getItemsFromDelimitedString(my getLocalizedStringForKey("STRINGS_FOR_SIX"), ",") -- {"six"}
	set stringsForSeven to my getItemsFromDelimitedString(my getLocalizedStringForKey("STRINGS_FOR_SEVEN"), ",") -- {"seven"}
	set stringsForEight to my getItemsFromDelimitedString(my getLocalizedStringForKey("STRINGS_FOR_EIGHT"), ",") -- {"ate", "eight"}
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
		set thisInteger to thisString as integer
		return thisInteger
	on error errorMessage
		return thisString
	end try
end integerValueForString

(* RECORD HANDLERS *)

on recordFromLabelsAndValues(theseLabels, theseValues)
	set theResult to current application's NSDictionary's dictionaryWithObjects:theseValues forKeys:theseLabels
	return theResult as record
end recordFromLabelsAndValues

(* ARRAY HANDLERS *)

on sortListOfStrings(theList)
	set theArray to current application's NSArray's arrayWithArray:theList
	set theArray to theArray's sortedArrayUsingSelector:"localizedStandardCompare:"
	return theArray as list
end sortListOfStrings

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

on deleteListItemsAtIndexes(theIndexes, theList)
	set theArray to current application's NSMutableArray's arrayWithArray:theList
	set theSet to current application's NSMutableIndexSet's indexSet()
	repeat with anIndex in theIndexes
		(theSet's addIndex:(anIndex - 1))
	end repeat
	theArray's removeObjectsAtIndexes:theSet
	return theArray as list
end deleteListItemsAtIndexes

on indexOfItemInList(aValue, theList)
	set theArray to current application's NSArray's arrayWithArray:theList
	set theIndex to theArray's indexOfObject:aValue
	return (theIndex + 1)
end indexOfItemInList

(* STRING TO NUMBER *)
on numericValueForString(thisString)
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
end numericValueForString


(* PROPERTY LIST HANDLERS *)

on storeRecord:theRecord inPath:thePath
	set theData to current application's NSPropertyListSerialization's dataWithPropertyList:theRecord format:(current application's NSPropertyListXMLFormat_v1_0) options:0 |error|:(missing value)
	theData's writeToFile:thePath atomically:true
end storeRecord:inPath:

(* USER INTERACTION *)

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

on promptForInput(displayedPrompt, spokenPrompt, defaultAnswerString, answerIsRequired, continueButtonTitle, appID)
	if appID is "" or appID is missing value then
		set aWorkspace to current application's NSWorkspace's sharedWorkspace
		set frontmostApp to aWorkspace's frontmostApplication
		set appID to (frontmostApp's bundleIdentifier) as text
	end if
	try
		set cancelButtonTitle to getLocalizedStringForKey("CANCEL_BUTTON_TITLE")
		say spokenPrompt without waiting until completion
		repeat
			tell application id appID
				activate
				display dialog displayedPrompt default answer defaultAnswerString buttons {cancelButtonTitle, continueButtonTitle} default button 2
				set textInput to the text returned of the result
				if answerIsRequired then
					if textInput is not "" then
						return textInput
					else
						say (my getLocalizedStringForKey("INPUT_REQUIRED")) without waiting until completion
					end if
				else
					return textInput
				end if
			end tell
		end repeat
		return true
	on error errorMessage
		log errorMessage
		-- return false
		error number -128
	end try
end promptForInput

on requestPositiveIntegerFromUserWithPrompt(aPrompt, defaultValue, targetAppID)
	if targetAppID is "" or targetAppID is missing value then
		set aWorkspace to current application's NSWorkspace's sharedWorkspace
		set frontmostApp to aWorkspace's frontmostApplication
		set appID to (frontmostApp's bundleIdentifier) as text
	end if
	tell application id appID
		activate
		repeat
			try
				display dialog aPrompt default answer defaultValue
				set thisInteger to the text returned of the result as integer
				if thisInteger is greater than 0 then
					return thisInteger
				else
					beep
				end if
			on error number errorNumber
				if errorNumber is -128 then return false
				beep
			end try
		end repeat
	end tell
end requestPositiveIntegerFromUserWithPrompt

on getLocalizedStringForKey(thisKey)
	set thisBundlePath to (path to me)
	return (localized string thisKey in bundle thisBundlePath)
end getLocalizedStringForKey

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

