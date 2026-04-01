-- USER SETABLE PROPERTIES
property senderFirstNamePlaceholder : "SENDERFIRSTNAME"
property senderLastNamePlaceholder : "SENDERLASTNAME"
property senderEmailAddressPlaceholder : "SENDEREMAILADDRESS"
property senderFullAddressPlaceholder : "SENDERFULLADDRESS"
property senderPhoneNumberPlaceholder : "SENDERPHONENUMBER"

property recipientFirstNamePlaceholder : "RECIPIENTFIRSTNAME"
property recipientLastNamePlaceholder : "RECIPIENTLASTNAME"
property recipientFullAddressPlaceholder : "RECIPIENTFULLADDRESS"

property attemptMailSend : false

property requireRecipientAddress : false

global peopleCount, recipientGroup

tell application "Contacts"
	activate
	try
		-- DISPLAY OPENING DIALOG WITH SETABLE PREFERENCES
		repeat
			if attemptMailSend is false then
				set autoSendState to "OFF"
			else
				set autoSendState to "ON"
			end if
			display dialog "This script will perform a Mail Merge between a Pages tagged-template and a chosen Contacts group." & return & return & "Contact data requirements for the sender are: First Name, Last Name, eMail Address, Mailing Address, and phone." & return & return & "Contact data requirements for recipients are: First Name, Last Name, and eMail Address." & return & return & "AUTO-SEND: " & autoSendState with icon 1 buttons {"Cancel", "Set Prefs", "Begin"} default button 3
			if the button returned of the result is "Begin" then
				exit repeat
			else
				display dialog "Set AUTO-SEND to:" buttons {"Cancel", "OFF", "ON"} default button autoSendState
				if the button returned of the result is "OFF" then
					set attemptMailSend to false
				else
					set attemptMailSend to true
				end if
			end if
		end repeat
		
		-- CHECK AND RETRIEVE THE SENDER DATA
		-- assumes that the sender is the default Contact card
		set thisPerson to my card
		if thisPerson is missing value then error number 10000
		
		-- get the sender’s data
		tell thisPerson
			set senderFirstName to first name
			set senderLastName to last name
			if senderFirstName is missing value or senderLastName is missing value then
				error number 10001
			end if
			
			set the emailCount to the count of emails
			if the emailCount is 0 then
				error number 10002
			else if the emailCount is 1 then
				set senderEmailAddress to the value of first email
			else -- multiple email addresses, prompt the user to pick one
				set theseEmailAddress to the value of every email
				set senderEmailAddress to ¬
					(choose from list theseEmailAddress with prompt ¬
						"Pick the sender email address to use:" default items (item 1 of theseEmailAddress))
				if senderEmailAddress is false then error number -128
				set senderEmailAddress to senderEmailAddress as string
			end if
			
			set the addressCount to the count of addresses
			if the addressCount is 0 then
				error number 10003
			else if the addressCount is 1 then
				set senderAddress to the formatted address of the first address
			else -- multiple addresses, prompt the user to pick one
				set theseAddresses to the formatted address of every address
				set senderAddress to ¬
					(choose from list theseAddresses with prompt ¬
						"Pick the sender address to use:" default items (item 1 of theseAddresses))
				if senderAddress is false then error number -128
				set senderAddress to senderAddress as string
			end if
			
			set the phoneCount to the count of phones
			if the phoneCount is 0 then
				error number 10004
			else if the phoneCount is 1 then
				set senderPhoneNumber to the value of first phone of it
			else -- multiple phone numbers, prompt the user to pick one
				set thesePhoneNumbers to the value of every phone
				set senderPhoneNumber to ¬
					(choose from list thesePhoneNumbers with prompt ¬
						"Pick the sender phone number to use:" default items (item 1 of thesePhoneNumbers))
				if senderPhoneNumber is false then error number -128
				set senderPhoneNumber to senderPhoneNumber as string
			end if
		end tell
		
		-- CHECK AND PROMPT FOR TARGET GROUP
		set groupCount to count of groups
		if the groupCount is 0 then
			error number 10005
		else if the groupCount is 1 then
			set recipientGroup to group 1
			set recipientGroupName to name of recipientGroup
		else -- multiple groups, prompt the user to pick one
			set theseGroupNames to the name of every group
			set recipientGroupName to ¬
				(choose from list theseGroupNames with prompt ¬
					"Pick the recipient Contacts group:" default items (item 1 of theseGroupNames))
			if recipientGroupName is false then error number -128
			set recipientGroupName to recipientGroupName as string
			set recipientGroup to group recipientGroupName
		end if
		
		-- CHECK GROUP FOR PEOPLE
		set peopleCount to the count of people of recipientGroup
		if the groupCount is 0 then
			error number 10006
		end if
		
	on error errorMessage number errorNumber
		if errorNumber is 10000 then
			set errorNumber to "NO DEFAULT CARD"
			set errorMessage to ¬
				"No person in this Contacts database is set to be the default card or “My Card.” Select a person and choose “Make This My Card” from the Card menu."
		else if errorNumber is 10001 then
			set selection to my card
			set errorNumber to "MISSING SENDER INFO"
			set errorMessage to ¬
				"The current default card is missing a value for the First Name or Last Name fields."
		else if errorNumber is 10002 then
			set selection to my card
			set errorNumber to "MISSING EMAIL ADDRESS"
			set errorMessage to ¬
				"The current default card is missing a value for the email address field."
		else if errorNumber is 10003 then
			set selection to my card
			set errorNumber to "MISSING MAILING ADDRESS"
			set errorMessage to ¬
				"The current default card is missing a value for the address fields."
		else if errorNumber is 10004 then
			set selection to my card
			set errorNumber to "MISSING PHONE NUMBER"
			set errorMessage to ¬
				"The current default card is missing a value for the phone number field."
		else if errorNumber is 10005 then
			set errorNumber to "MISSING GROUPS"
			set errorMessage to ¬
				"There are no groups in the current contact database."
		else if errorNumber is 10006 then
			set errorNumber to "MISSING PEOPLE"
			set errorMessage to ¬
				"The chosen Contacts group contains no people."
		end if
		if errorNumber is not -128 then
			display alert (errorNumber as string) message errorMessage
		end if
		error number -128
	end try
end tell

-- LOCATE THE TEMPORARY ITEMS FOLDER
set thisDirectoryHFSPath to (path to temporary items folder) as string

-- SWITCH TO PAGES
tell application "Pages"
	activate
	try
		-- CHECK TO SEE ALL DOCUMENTS ARE CLOSED
		if the (count of documents) is not 0 then error number 10000
		
		-- GET A LIST OF THE INSTALLED USER TEMPLATES AND PROMPT USER TO PICK THE ONE TO USE
		set userTemplateNames to the name of every template whose id of it begins with "User/"
		if userTemplateNames is {} then error number 10001
		
		set the chosenTemplateName to ¬
			(choose from list userTemplateNames with prompt ¬
				"Pick the tagged Pages template to use:" default items (item 1 of userTemplateNames))
		if chosenTemplateName is false then error number -128
		set chosenTemplateName to chosenTemplateName as string
		
		-- PROMPT FOR THE NAME OF THE EXPORTED PDFs
		repeat
			display dialog "Enter the name to use for the exported document:" default answer ""
			set thisDocName to the text returned of the result
			if thisDocName is not "" then
				if thisDocName does not end with ".pdf" then
					set exportDocName to thisDocName & ".pdf"
				else
					set exportDocName to thisDocName
				end if
				exit repeat
			end if
		end repeat
		
		-- PROMPT FOR PASSWORD (OPTIONAL)
		repeat
			display dialog "Enter a password for the PDF file:" default answer ¬
				"" buttons {"Cancel", "No Password", "OK"} default button 3 with hidden answer
			copy the result to {button returned:buttonPressed, text returned:firstPassword}
			if buttonPressed is "No Password" then
				set usePDFEncryption to false
				exit repeat
			else
				display dialog "Enter the password again:" default answer ¬
					"" buttons {"Cancel", "No Password", "OK"} default button 3 with hidden answer
				copy the result to {button returned:buttonPressed, text returned:secondPassword}
				if buttonPressed is "No Password" then
					set usePDFEncryption to false
					exit repeat
				else
					if firstPassword is not secondPassword then
						display dialog "Passwords do no match." buttons {"Cancel", "Try Again"} default button 2
					else
						set providedPassword to the firstPassword
						set usePDFEncryption to true
						exit repeat
					end if
				end if
			end if
		end repeat
		
		-- PROMPT FOR MAIL SUBJECT LINE
		set defaultMessageSubject to "Document from " & senderFirstName & space & senderLastName
		repeat
			display dialog "Enter the subject for the created Mail message:" default answer defaultMessageSubject
			set the outgoingMessageSubject to the text returned of the result
			if the outgoingMessageSubject is not "" then exit repeat
		end repeat
		
		-- OPEN TEMPLATE AND CHECK FOR OPTIONAL PLACEHOLDERS
		display dialog "Scanning template…" buttons {"•"} default button 1 giving up after 1
		set thisDocument to ¬
			make new document with properties {document template:template chosenTemplateName}
		tell body text of thisDocument
			set recipientFullAddressPlaceholderCount to ¬
				the count of (every word where it is recipientFullAddressPlaceholder)
		end tell
		close thisDocument saving no
		display dialog "Scan complete. Beginning Mail Merge…" buttons ¬
			{"•"} default button 1 giving up after 1
		
		-- BEGIN MERGE
		set the errorLog to "MAIL MERGE ERROR LOG"
		set createdMessages to {}
		repeat with i from 1 to the peopleCount
			set skipFlag to false
			tell application "Contacts"
				set thisPerson to person i of the recipientGroup
				set thisPersonIDString to the id of person i
				try
					set recipientFirstName to first name of thisPerson
					if recipientFirstName is missing value then error
				on error
					set recipientFirstName to "NO-FIRST-NAME"
					set skipFlag to true
					set the errorLog to ¬
						errorLog & return & recipientFirstName & space & thisPersonIDString
				end try
				try
					set recipientLastName to last name of thisPerson
					if recipientLastName is missing value then error
				on error
					set recipientLastName to "NO-LAST-NAME"
					set skipFlag to true
					set the errorLog to ¬
						errorLog & return & recipientLastName & space & thisPersonIDString
				end try
				try
					set recipientFullAddress to the formatted address of the first address of thisPerson
					if recipientFullAddressPlaceholderCount is not 0 and ¬
						recipientFullAddress is missing value then error
				on error
					set recipientFullAddress to "NO-FULL-ADDRESS"
					set skipFlag to requireRecipientAddress
					set the errorLog to ¬
						errorLog & return & recipientFullAddress & space & thisPersonIDString
				end try
				try
					set recipientEmailAddress to the value of the first email of thisPerson
					if recipientEmailAddress is missing value then error
				on error
					set recipientEmailAddress to "NO-EMAIL-ADDRESS"
					set skipFlag to true
					set the errorLog to ¬
						errorLog & return & recipientEmailAddress & space & thisPersonIDString
				end try
			end tell
			
			if skipFlag is false then
				-- open a copy of the tagged template
				set thisDocument to ¬
					make new document with properties ¬
						{document template:template chosenTemplateName}
				tell thisDocument
					-- replace the placeholders with the person data
					set placeholderWordReplacementStringPairings to {{senderFirstNamePlaceholder, senderFirstName}, {senderLastNamePlaceholder, senderLastName}, {senderEmailAddressPlaceholder, senderEmailAddress}, {senderFullAddressPlaceholder, senderAddress}, {senderPhoneNumberPlaceholder, senderPhoneNumber}, {recipientFirstNamePlaceholder, recipientFirstName}, {recipientLastNamePlaceholder, recipientLastName}, {recipientFullAddressPlaceholder, recipientFullAddress}}
					tell body text
						with timeout of 600 seconds -- allow up to 10 minutes to process really long documents
							repeat with i from 1 to the count of placeholderWordReplacementStringPairings
								copy item i of placeholderWordReplacementStringPairings to ¬
									{placeholderWord, replacementString}
								my replaceWordWithStringInBodyText(placeholderWord, replacementString)
							end repeat
						end timeout
					end tell
				end tell
				
				-- export the PDF to the temporary items folder
				set the targetExportFileHFSPath to (thisDirectoryHFSPath & exportDocName)
				if usePDFEncryption is true then
					export thisDocument to file targetExportFileHFSPath ¬
						as PDF with properties {password:providedPassword}
				else
					export thisDocument to file targetExportFileHFSPath as PDF
				end if
				
				-- close the new document without saving it
				close thisDocument saving no
				
				-- make a new message, attaching the exported PDF file
				tell application "Mail"
					set thisMessage to make new outgoing message with properties ¬
						{subject:outgoingMessageSubject, visible:true}
					tell thisMessage
						make new to recipient with properties ¬
							{address:recipientEmailAddress, name:(recipientFirstName & space & recipientLastName)}
						make new attachment at end of paragraphs of content with properties ¬
							{file name:file targetExportFileHFSPath}
					end tell
					set the end of createdMessages to thisMessage
				end tell
				
				-- delete the exported PDF file
				tell application "Finder"
					move document file targetExportFileHFSPath to the trash
				end tell
			end if
		end repeat
		
		-- SEND THE CREATED MESSAGES (OPTIONAL)
		if attemptMailSend is true then
			try
				tell application "Mail"
					activate
					repeat with i from 1 to the count of the createdMessages
						set thisMessage to item i of the createdMessages
						send thisMessage
					end repeat
				end tell
			on error errorMessage
				set the errorLog to errorLog & return & ¬
					"Attempt at sending messages failed." & space & errorMessage
			end try
		else
			tell application "Mail" to activate
		end if
		
		-- CHECK THE ERROR LOG
		if the (count of paragraphs of errorLog) is greater than 1 then
			-- create a new Pages document with the eror log
			set thisDocument to ¬
				make new document with properties {document template:template "Blank"}
			set body text of thisDocument to errorLog
			error number 10002
		else
			-- display dialog "Mail Merge completed." buttons {"OK"} default button 1
			display notification "Process completed." with title "Mail Merge with Contacts Group"
		end if
	on error errorMessage number errorNumber
		if errorNumber is 10000 then
			set errorNumber to "OPEN DOCUMENTS"
			set errorMessage to ¬
				"Please close all documents before running this script."
		else if errorNumber is 10001 then
			set errorNumber to "NO USER TEMPLATES"
			set errorMessage to ¬
				"There are no Pages user templates installed on this computer."
		else if errorNumber is 10002 then
			set errorNumber to "MAIL MERGE ERRORS"
			set errorMessage to ¬
				"The open document lists the errors occuring during the Mail Merge."
		end if
		if errorNumber is not -128 then
			if errorNumber is in {10002} then
				display notification "Errors occured." with title "Mail Merge with Contacts Group"
			end if
			display alert (errorNumber as string) message errorMessage
		end if
		error number -128
	end try
end tell

on replaceWordWithStringInBodyText(searchWord, replacementString)
	tell application "Pages"
		activate
		tell the front document
			tell body text
				-- start at the end and go to the beginning
				repeat with i from the (count of paragraphs) to 1 by -1
					tell paragraph i
						repeat
							try
								if exists searchWord then
									set (last word where it is searchWord) to replacementString
								else
									exit repeat
								end if
							on error errorMessage
								exit repeat
							end try
						end repeat
					end tell
				end repeat
			end tell
		end tell
		return true
	end tell
end replaceWordWithStringInBodyText
