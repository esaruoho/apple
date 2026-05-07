use framework "Foundation"
use scripting additions

property logEnabled : true

(* COMPOSE *)

on replyToSeletedMesssage()
	try
		set unknownRespondee to "To whom it may concern"
		tell application id "com.apple.mail"
			activate
			if (count of message viewers) is 0 then
				error "NO_MESSAGE_VIEWER"
			end if
			set theseItems to (get selected messages of the front message viewer)
			if theseItems is missing value then
				error "NO_MESSAGE_SELECTED"
			end if
			set thisMessage to (get first item of (get selected messages of the front message viewer))
			set messageSender to sender of thisMessage
			set senderName to my extractSenderNameFromSenderObject(messageSender)
			if senderName is not unknownRespondee then
				set greetingName to the first word of senderName
			else
				set greetingName to senderName
			end if
			set messageSubject to subject of thisMessage
			set newMessage to reply thisMessage with opening window and reply to all
		end tell
		delay 0.5
		tell application "System Events"
			keystroke greetingName & "," & return & return
		end tell
		tell application id "com.apple.mail"
			return newMessage
		end tell
	on error errorMessage number errorNumber
		if errorNumber is not -128 then
			my displaySpokenErrorAlert(errorMessage, "com.apple.mail")
		end if
		error number -128
	end try
end replyToSeletedMesssage

on createNewOutgoingMailMessage(messageSubject, messageBody, messageAttachments, shouldActivate)
	tell application id "com.apple.Mail"
		if shouldActivate is true then
			activate
		end if
		set aMessage to make new outgoing message with properties {subject:messageSubject, content:(messageBody & return & return & return)}
		if messageAttachments is not {} then
			tell aMessage
				repeat with i from 1 to the count of messageAttachments
					set thisItem to item i of messageAttachments
					make new attachment at end of last paragraph of content with properties {file name:thisItem}
				end repeat
			end tell
		end if
		return aMessage
	end tell
end createNewOutgoingMailMessage

on insertLegalize()
	set aString to "THIS TRANSMISSION MAY BE PRIVILEGED AND MAY CONTAIN CONFIDENTIAL INFORMATION INTENDED ONLY FOR THE PERSON(S) NAMED ABOVE. ANY OTHER DISTRIBUTION, RE-TRANSMISSION, COPYING OR DISCLOSURE IS STRICTLY PROHIBITED. IF YOU HAVE RECEIVED THIS TRANSMISSION IN ERROR, PLEASE NOTIFY ME IMMEDIATELY BY TELEPHONE OR RETURN E-MAIL, AND DELETE THIS FILE/MESSAGE FROM YOUR SYSTEM."
	tell application "System Events" to keystroke aString
end insertLegalize

(* MANAGE *)

on moveToJunkFolder()
	try
		tell application "Mail"
			activate
			if (count of message viewers) is 0 then
				error "NO_MESSAGE_VIEWER"
			end if
			set theseItems to (get selected messages of the front message viewer)
			if theseItems is missing value then
				error "NO_MESSAGES_SELECTED"
			end if
			repeat with i from 1 to the count of theseItems
				move (item i of theseItems) to junk mailbox
			end repeat
		end tell
		say (getLocalizedStringForKey("SUCCESSFUL_COMPLETION_PHRASE"))
	on error errorMessage number errorNumber
		if errorNumber is not -128 then
			my displaySpokenErrorAlert(errorMessage, "com.apple.mail")
		end if
		error number -128
	end try
end moveToJunkFolder

(* INTERFACE *)

on selectInMailbox()
	try
		tell application "Mail"
			activate
			if (count of message viewers) is 0 then
				error "NO_MESSAGE_VIEWER"
			end if
			tell front message viewer
				set selected mailboxes to {inbox}
			end tell
		end tell
	on error errorMessage number errorNumber
		if errorNumber is not -128 then
			my displaySpokenErrorAlert(errorMessage, "com.apple.mail")
		end if
		error number -128
	end try
end selectInMailbox

on selectOutMailbox()
	try
		tell application "Mail"
			activate
			if (count of message viewers) is 0 then
				error "NO_MESSAGE_VIEWER"
			end if
			tell front message viewer
				set selected mailboxes to {outbox}
			end tell
		end tell
	on error errorMessage number errorNumber
		if errorNumber is not -128 then
			my displaySpokenErrorAlert(errorMessage, "com.apple.mail")
		end if
		error number -128
	end try
end selectOutMailbox

on selectJunkMailbox()
	try
		tell application "Mail"
			activate
			if (count of message viewers) is 0 then
				error "NO_MESSAGE_VIEWER"
			end if
			tell front message viewer
				set selected mailboxes to {junk mailbox}
			end tell
		end tell
	on error errorMessage number errorNumber
		if errorNumber is not -128 then
			my displaySpokenErrorAlert(errorMessage, "com.apple.mail")
		end if
		error number -128
	end try
end selectJunkMailbox

on selectTrashMailbox()
	try
		tell application "Mail"
			activate
			if (count of message viewers) is 0 then
				error "NO_MESSAGE_VIEWER"
			end if
			tell front message viewer
				set selected mailboxes to {trash mailbox}
			end tell
		end tell
	on error errorMessage number errorNumber
		if errorNumber is not -128 then
			my displaySpokenErrorAlert(errorMessage, "com.apple.mail")
		end if
		error number -128
	end try
end selectTrashMailbox

on selectSentMialbox()
	try
		tell application "Mail"
			activate
			if (count of message viewers) is 0 then
				error "NO_MESSAGE_VIEWER"
			end if
			tell front message viewer
				set selected mailboxes to {sent mailbox}
			end tell
		end tell
	on error errorMessage number errorNumber
		if errorNumber is not -128 then
			my displaySpokenErrorAlert(errorMessage, "com.apple.mail")
		end if
		error number -128
	end try
end selectSentMialbox

on selectDraftsMailbox()
	try
		tell application "Mail"
			activate
			if (count of message viewers) is 0 then
				error "NO_MESSAGE_VIEWER"
			end if
			tell front message viewer
				set selected mailboxes to {drafts mailbox}
			end tell
		end tell
	on error errorMessage number errorNumber
		if errorNumber is not -128 then
			my displaySpokenErrorAlert(errorMessage, "com.apple.mail")
		end if
		error number -128
	end try
end selectDraftsMailbox



(* SUPPORT HANDLERS *)

on extractSenderNameFromSenderObject(messageSender)
	set x to the offset of "<" in messageSender
	if x is 0 then
		set senderName to messageSender
	else
		set y to the offset of ">" in messageSender
		if y is 0 then
			set senderName to messageSender
		else
			if x is 1 then
				set senderName to unknownRespondee
			else
				set senderName to text 1 thru (x - 1) of messageSender
				set senderName to my trimWhiteSpaceAroundString(senderName)
			end if
		end if
	end if
	return senderName
end extractSenderNameFromSenderObject

on trimWhiteSpaceAroundString(thisString)
	set theString to current application's NSString's stringWithString:thisString
	set theWhiteSet to current application's NSCharacterSet's whitespaceAndNewlineCharacterSet()
	set theString to theString's stringByTrimmingCharactersInSet:theWhiteSet
	return theString as text
end trimWhiteSpaceAroundString

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

