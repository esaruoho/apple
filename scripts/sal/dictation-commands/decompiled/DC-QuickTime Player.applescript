
(* RECORDING *)

on newScreenRecordingDocument(startRecording)
	try
		tell application id "com.apple.QuickTimePlayerX"
			activate
			stop every document
			set newDoc to new screen recording
			if startRecording is true then
				my countdownToRecord()
				delay 0.5
				start newDoc
			else
				my announceCompletion()
				return newDoc
			end if
		end tell
	on error errorMessage number errorNumber
		if errorNumber is not -128 then
			my displaySpokenErrorAlert(errorMessage, "com.apple.QuickTimePlayerX")
		end if
		error number -128
	end try
end newScreenRecordingDocument

on newAudioRecordingDocument(startRecording)
	try
		tell application id "com.apple.QuickTimePlayerX"
			activate
			stop every document
			set newDoc to new audio recording
			if startRecording is true then
				my countdownToRecord()
				delay 0.5
				start newDoc
			else
				my announceCompletion()
				return newDoc
			end if
		end tell
	on error errorMessage number errorNumber
		if errorNumber is not -128 then
			my displaySpokenErrorAlert(errorMessage, "com.apple.QuickTimePlayerX")
		end if
		error number -128
	end try
end newAudioRecordingDocument

on newMovieRecordingDocument(startRecording)
	try
		tell application id "com.apple.QuickTimePlayerX"
			activate
			stop every document
			set newDoc to new movie recording
			if startRecording is true then
				my countdownToRecord()
				delay 0.5
				start newDoc
			else
				my announceCompletion()
				return newDoc
			end if
		end tell
	on error errorMessage number errorNumber
		if errorNumber is not -128 then
			my displaySpokenErrorAlert(errorMessage, "com.apple.QuickTimePlayerX")
		end if
		error number -128
	end try
end newMovieRecordingDocument

on stopEveryDocument()
	try
		tell application id "com.apple.QuickTimePlayerX"
			activate
			stop every document
		end tell
	on error errorMessage number errorNumber
		if errorNumber is not -128 then
			my displaySpokenErrorAlert(errorMessage, "com.apple.QuickTimePlayerX")
		end if
		error number -128
	end try
end stopEveryDocument

on stopAllRecording()
	try
		tell application id "com.apple.QuickTimePlayerX"
			activate
			stop (every document whose name is "Audio Recording" or name is "Screen Recording" or name is "Movie Recording")
		end tell
	on error errorMessage number errorNumber
		if errorNumber is not -128 then
			my displaySpokenErrorAlert(errorMessage, "com.apple.QuickTimePlayerX")
		end if
		error number -128
	end try
end stopAllRecording

(* EDITING *)

on trimFromDocumentEnd(trimDuration)
	try
		tell application id "com.apple.QuickTimePlayerX"
			if not (exists document 1) then error number -128
			set aDuration to the duration of document 1
			if trimDuration is less than aDuration then
				trim document 1 from 0 to aDuration - trimDuration
			else
				error "TOO_SHORT_TO_TRIM"
			end if
		end tell
		my announceCompletion()
	on error errorMessage number errorNumber
		if errorNumber is not -128 then
			my displaySpokenErrorAlert(errorMessage, "com.apple.QuickTimePlayerX")
		end if
		error number -128
	end try
end trimFromDocumentEnd

(* DOCUMENT *)

on closeFrontDocWithoutSaving()
	try
		tell application id "com.apple.QuickTimePlayerX"
			activate
			if not (exists document 1) then error number -128
			close document 1 without saving
		end tell
	on error errorMessage number errorNumber
		if errorNumber is not -128 then
			my displaySpokenErrorAlert(errorMessage, "com.apple.QuickTimePlayerX")
		end if
		error number -128
	end try
end closeFrontDocWithoutSaving

on saveFrontDocumentToMoviesFolder()
	try
		tell application id "com.apple.QuickTimePlayerX"
			if not (exists document 1) then error number -128
			if (get file of front document) is missing value then
				set dialogPrompt to my getLocalizedStringForKey("SAVE_NEW_DOC_DISPLAY_PROMPT")
				set spokenPrompt to my getLocalizedStringForKey("SAVE_NEW_DOC_SPOKEN_PROMPT")
				set continueButtonTitle to my getLocalizedStringForKey("CONTINUE_BUTTON_TITLE")
				tell script "DC-Support"
					set nameForFile to promptForInput(dialogPrompt, spokenPrompt, "", true, continueButtonTitle, "com.apple.QuickTimePlayerX")
				end tell
				set POSIXPath to script "DC-Workspace"'s derivePathForDocumentInMoviesFolder(nameForFile, "qtpxcomposition")
				save front document in (POSIXPath as POSIX file)
			else
				save front document
			end if
		end tell
		my announceCompletion()
	on error errorMessage number errorNumber
		return errorMessage
		if errorNumber is not -128 then
			my displaySpokenErrorAlert(errorMessage, "com.apple.QuickTimePlayerX")
		end if
		error number -128
	end try
end saveFrontDocumentToMoviesFolder

(* PLAYBACK *)

on playFromTheBeginning()
	try
		tell application id "com.apple.QuickTimePlayerX"
			activate
			if not (exists document 1) then error number -128
			set the current time of document 1 to 0
			play document 1
		end tell
	on error errorMessage number errorNumber
		if errorNumber is not -128 then
			my displaySpokenErrorAlert(errorMessage, "com.apple.QuickTimePlayerX")
		end if
		error number -128
	end try
end playFromTheBeginning

(* SUPPORT *)

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

on speakWithMutedInput(stringToSpeak)
	try
		set volumeLevel to missing value
		tell current application
			set volumeLevel to input volume of (get volume settings)
			set volume input volume 0
			say stringToSpeak with waiting until completion
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
end speakWithMutedInput

on logThis(thisText)
	if logEnabled then current application's NSLog("%@", thisText)
end logThis

on speakThisWithDefaultVoice(thisString)
	set thisVoiceID to current application's NSSpeechSynthesizer's defaultVoice()
	set thisSpeechSynthesizer to current application's NSSpeechSynthesizer's alloc's initWithVoice:thisVoiceID
	thisSpeechSynthesizer's startSpeakingString:thisString
end speakThisWithDefaultVoice

on getLocalizedStringForKey(thisKey)
	set thisBundlePath to (path to me)
	return (localized string thisKey in bundle thisBundlePath)
end getLocalizedStringForKey

on announceCompletion()
	say (my getLocalizedStringForKey("SUCCESSFUL_COMPLETION_PHRASE"))
end announceCompletion

on announceReady()
	say (my getLocalizedStringForKey("READY_PHRASE"))
end announceReady

on countdownToRecord()
	say (my getLocalizedStringForKey("COUNTDOWN_PHRASE"))
end countdownToRecord

