use framework "Foundation"
use scripting additions

(* LINES *)

on overlayRuleOfThirdsGrid()
	try
		tell application id "com.apple.iWork.Keynote"
			activate
			if not (exists document 1) then
				error "KEYNOTE_NO_DOCUMENT"
			end if
			tell document 1
				set documentWidth to its «class sitw»
				set documentHeight to its «class sith»
				set documentWidthThird to documentWidth div 3
				set documentHeightThird to documentHeight div 3
				tell «class crsl»
					-- HORIZONTAL LINES
					set thisLine to make new «class iWln» with properties {«class lnsp»:{0, documentHeightThird}, «class lnep»:{documentWidth, documentHeightThird}, «class sirs»:false, «class sirv»:100}
					set thisLine to make new «class iWln» with properties {«class lnsp»:{0, documentHeightThird * 2}, «class lnep»:{documentWidth, documentHeightThird * 2}, «class sirs»:false, «class sirv»:100}
					-- VERTICAL LINES
					set thisLine to make new «class iWln» with properties {«class lnsp»:{documentWidthThird, 0}, «class lnep»:{documentWidthThird, documentHeight}, «class sirs»:false, «class sirv»:100}
					set thisLine to make new «class iWln» with properties {«class lnsp»:{documentWidthThird * 2, 0}, «class lnep»:{documentWidthThird * 2, documentHeight}, «class sirs»:false, «class sirv»:100}
				end tell
			end tell
		end tell
		announceCompletion()
	on error errorMessage number errorNumber
		if errorNumber is not -128 then
			my displaySpokenErrorAlert(errorMessage, "com.apple.iWork.Keynote")
		end if
		error number -128
	end try
end overlayRuleOfThirdsGrid

on overlayRuleOfThirdsOnSelectedImage()
	try
		tell script "DC-Keynote"
			set thisImage to getSelectedImageOrOnlyImage()
		end tell
		tell application id "com.apple.iWork.Keynote"
			activate
			set documentWidth to «class sitw» of document 1
			set documentHeight to «class sith» of document 1
			
			copy «class sipo» of thisImage to {imageHorizontalOffset, imageVerticalOffset}
			set thisImageWidth to the «class sitw» of thisImage
			set thisImageHeight to the «class sith» of thisImage
			set imageWidthThird to thisImageWidth div 3
			set imageHeightThird to thisImageHeight div 3
			
			tell «class crsl» of document 1
				-- HORIZONTAL LINES
				set thisLine to make new «class iWln» with properties {«class lnsp»:{imageHorizontalOffset, (imageVerticalOffset + imageHeightThird)}, «class lnep»:{(imageHorizontalOffset + thisImageWidth), (imageVerticalOffset + imageHeightThird)}, «class sirs»:false, «class sirv»:100}
				set thisLine to make new «class iWln» with properties {«class lnsp»:{imageHorizontalOffset, (imageHeightThird * 2) + imageVerticalOffset}, «class lnep»:{(imageHorizontalOffset + thisImageWidth), (imageHeightThird * 2) + imageVerticalOffset}, «class sirs»:false, «class sirv»:100}
				
				-- VERTICAL LINES
				set thisLine to make new «class iWln» with properties {«class lnsp»:{(imageHorizontalOffset + imageWidthThird), imageVerticalOffset}, «class lnep»:{(imageHorizontalOffset + imageWidthThird), (imageVerticalOffset + thisImageHeight)}, «class sirs»:false, «class sirv»:100}
				set thisLine to make new «class iWln» with properties {«class lnsp»:{imageHorizontalOffset + (imageWidthThird * 2), imageVerticalOffset}, «class lnep»:{imageHorizontalOffset + (imageWidthThird * 2), (imageVerticalOffset + thisImageHeight)}, «class sirs»:false, «class sirv»:100}
			end tell
		end tell
		announceCompletion()
	on error errorMessage number errorNumber
		if errorNumber is not -128 then
			my displaySpokenErrorAlert(errorMessage, "com.apple.iWork.Keynote")
		end if
		error number -128
	end try
end overlayRuleOfThirdsOnSelectedImage

on promptForLineDeletion()
	try
		tell application id "com.apple.iWork.Keynote"
			activate
			
			if not (exists document 1) then error "KEYNOTE_NO_DOCUMENT"
			
			display dialog "Delete lines from the current slide?" buttons {"Cancel", "Delete All", "Delete Unlocked"} default button 1
			set deletionOption to the button returned of the result
			tell document 1
				tell «class crsl»
					if deletionOption is "Delete All" then
						set «class pLck» of every «class iWln» to false
						delete every «class iWln»
					else
						delete (every «class iWln» whose «class pLck» is false)
					end if
				end tell
			end tell
		end tell
		announceCompletion()
	on error errorMessage number errorNumber
		if errorNumber is not -128 then
			my displaySpokenErrorAlert(errorMessage, "com.apple.iWork.Keynote")
		end if
	end try
end promptForLineDeletion

on deleteAllLines(shouldConfirm)
	try
		tell application id "com.apple.iWork.Keynote"
			activate
			
			if not (exists document 1) then error "KEYNOTE_NO_DOCUMENT"
			
			if shouldConfirm is true then
				set confirmationPrompt to "Are you sure you want to delete all lines from the current slide?" & return & return & "This action cannot be undone."
				set confirmationSpokenPrompt to "Are you sure you want to delete all lines from the current slide?"
				say confirmationSpokenPrompt without waiting until completion
				display dialog confirmationPrompt with icon 2
				say " " with stopping current speech
			end if
			
			tell document 1
				tell «class crsl»
					set «class pLck» of every «class iWln» to false
					delete every «class iWln»
				end tell
			end tell
		end tell
		announceCompletion()
	on error errorMessage number errorNumber
		if errorNumber is not -128 then
			my displaySpokenErrorAlert(errorMessage, "com.apple.iWork.Keynote")
		end if
	end try
end deleteAllLines

on deleteUnlockedLines(shouldConfirm)
	try
		tell application id "com.apple.iWork.Keynote"
			activate
			
			if not (exists document 1) then error "KEYNOTE_NO_DOCUMENT"
			
			if shouldConfirm is true then
				set confirmationPrompt to "Are you sure you want to delete all unlocked lines from the current slide?" & return & return & "This action cannot be undone."
				set confirmationSpokenPrompt to "Are you sure you want to delete all unlocked lines from the current slide?"
				say confirmationSpokenPrompt without waiting until completion
				display dialog confirmationPrompt with icon 2
				say " " with stopping current speech
			end if
			
			tell document 1
				tell «class crsl»
					delete (every «class iWln» whose «class pLck» is false)
				end tell
			end tell
		end tell
		announceCompletion()
	on error errorMessage number errorNumber
		if errorNumber is not -128 then
			my displaySpokenErrorAlert(errorMessage, "com.apple.iWork.Keynote")
		end if
	end try
end deleteUnlockedLines

on deleteLockedLines(shouldConfirm)
	try
		tell application id "com.apple.iWork.Keynote"
			activate
			
			if not (exists document 1) then error "KEYNOTE_NO_DOCUMENT"
			
			if shouldConfirm is true then
				set confirmationPrompt to "Are you sure you want to delete all locked lines from the current slide?" & return & return & "This action cannot be undone."
				set confirmationSpokenPrompt to "Are you sure you want to delete all locked lines from the current slide?"
				say confirmationSpokenPrompt without waiting until completion
				display dialog confirmationPrompt with icon 2
				say " " with stopping current speech
			end if
			
			tell document 1
				tell «class crsl»
					delete (every «class iWln» whose «class pLck» is true)
				end tell
			end tell
		end tell
		announceCompletion()
	on error errorMessage number errorNumber
		if errorNumber is not -128 then
			my displaySpokenErrorAlert(errorMessage, "com.apple.iWork.Keynote")
		end if
	end try
end deleteLockedLines


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

