use framework "Foundation"
use scripting additions

on openDictationCommandsHelpBook()
	open location "help:openbook=com.apple.dictationcommands.help"
	-- store the JXA call to this handler
	set JXACommandString to "Library('DC-Help').openHelpBook();"
	tell script "DC-Support" to storeJXACommandString(JXACommandString)
end openDictationCommandsHelpBook

on openMainPage(shouldAnnouncePage)
	if shouldAnnouncePage is true then
		set speechString to my getLocalizedStringForKey("HELP_ANNOUNCEMENT")
		set delayTime to ((length of speechString) div 10)
		showAnchorWithSpokenOverlay("default-main", "Dictation Commands", speechString, delayTime)
	else
		-- set aHelpManager to current application's NSHelpManager's sharedHelpManager()
		my openHelpBookToAnchor("default-main", "Dictation Commands")
		-- open location "help:openbook=com.apple.dictationcommands.help"
	end if
end openMainPage

on openHelpBookToAnchor(bookAnchor, bookName)
	set aHelpManager to current application's NSHelpManager's sharedHelpManager()
	aHelpManager's openHelpAnchor:bookAnchor inBook:bookName
end openHelpBookToAnchor

on openDictationCommandsWebsite()
	open location "http://dictationcommands.com"
	
end openDictationCommandsWebsite

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

on showAnchorWithSpokenOverlay(bookAnchor, bookName, stringToSpeak, timeDelayInSeconds)
	try
		set volumeLevel to missing value
		tell current application
			set volumeLevel to input volume of (get volume settings)
			set volume input volume 0
			say stringToSpeak without waiting until completion
			set aHelpManager to current application's NSHelpManager's sharedHelpManager()
			aHelpManager's openHelpAnchor:"default-main" inBook:"Dictation Commands"
			delay timeDelayInSeconds
			set volume input volume volumeLevel
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
		return errorMessage
		my logThis(errorMessage)
	end try
end showAnchorWithSpokenOverlay


on findAndReplaceStringInText(sourceText, searchString, replacementString)
	set the sourceString to current application's NSString's stringWithString:sourceText
	-- Replace the search string with the replacement string, by calling a method on the newly created instance
	set the adjustedString to the sourceString's stringByReplacingOccurrencesOfString:searchString withString:replacementString
	return (adjustedString as string)
end findAndReplaceStringInText

on getLocalizedStringForKey(thisKey)
	tell current application
		set thisBundlePath to (path to me)
		return (localized string thisKey in bundle thisBundlePath)
	end tell
end getLocalizedStringForKey

