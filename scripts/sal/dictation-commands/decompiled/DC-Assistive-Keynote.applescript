use framework "Foundation"
use scripting additions

property silence1000 : " [[slnc 1000]] "
property silence750 : " [[slnc 750]] "
property silence500 : " [[slnc 500]] "
property silence250 : " [[slnc 250]] "

property soundDuration : 0.25
property soundVolume : 0.15

(* KEYNOTE PREFERENCES *)

on setLinkDetectionPreference(trueOrFalse)
	if trueOrFalse is true then
		tell current application
			do shell script "defaults write com.apple.iWork.Keynote TWSPAutomaticallyDetectLinks 1"
		end tell
	else
		tell current application
			do shell script "defaults write com.apple.iWork.Keynote TWSPAutomaticallyDetectLinks 0"
		end tell
	end if
	announceCompletion()
end setLinkDetectionPreference

on setQuoteSubstitutionPreference(trueOrFalse)
	if trueOrFalse is true then
		tell current application
			do shell script "defaults write com.apple.iWork.Keynote TSWPAutomaticQuoteSubstitution 1"
		end tell
	else
		tell current application
			do shell script "defaults write com.apple.iWork.Keynote TSWPAutomaticQuoteSubstitution 0"
		end tell
	end if
	announceCompletion()
end setQuoteSubstitutionPreference

on setDashSubstitutionPreference(trueOrFalse)
	if trueOrFalse is true then
		tell current application
			do shell script "defaults write com.apple.iWork.Keynote TSWPAutomaticDashSubstitution 1"
		end tell
	else
		tell current application
			do shell script "defaults write com.apple.iWork.Keynote TSWPAutomaticDashSubstitution 0"
		end tell
	end if
	announceCompletion()
end setDashSubstitutionPreference

on promptToSetDefaultAuthor()
	try
		tell application id "com.apple.iWork.Keynote"
			activate
			tell current application
				set authorString to (do shell script "defaults read com.apple.iWork.Keynote TSAICloudAuthorNameKey")
				display dialog "Enter the default author for creating Keynote documents:" default answer authorString
				set newAuthorString to the text returned of the result
				do shell script "defaults write com.apple.iWork.Keynote TSAICloudAuthorNameKey" & space & quoted form of newAuthorString
			end tell
		end tell
		announceCompletion()
	on error errorMessage
		log errorMessage
	end try
end promptToSetDefaultAuthor


(* OBJECT INFORMATION *)

-- CURRENT DOCUMENT
on speakInfoAboutCurrentDocument()
	try
		tell application id "com.apple.iWork.Keynote"
			set thisVersion to version of it
			activate
			if not (exists document 1) then
				error "KEYNOTE_NO_DOCUMENT"
			end if
			set playingStatus to «class Plng» of it
			tell front document
				set documentFile to file of it
				set documentName to the name of it
				set documentWidth to the «class sitw» of it
				set documentHeight to the «class sith» of it
				-- crashing bug accessing document theme in non-standard presentation (27393338)
				if thisVersion is greater than or equal to "7" then
					set templateName to the name of «class Kndt» of it
					set useDocumentTheme to true
				else -- for versions 6 or earlier, don't get theme of non-standard sizes
					if documentWidth is 1024 and documentHeight is 768 then
						set useDocumentTheme to true
						set templateName to the name of «class Kndt» of it
					else
						set useDocumentTheme to false
					end if
				end if
				set slideNumbersShowingStatus to «class Knsh» of it
				set slideCount to the count of every «class KnSd» of it
				set skippedCount to the count of (every «class KnSd» whose «class Kskp» is true)
				set currentSlideSlideNumber to the «class KSdN» of the «class crsl»
			end tell
		end tell
		if documentFile is missing value then
			set documentSavedStatus to "The document has not yet been saved."
		else
			set documentSavedStatus to "The document has been previously saved."
		end if
		if slideCount is 1 then
			set slideTerm to "slide"
		else
			set slideTerm to "slides"
		end if
		if skippedCount is 1 then
			set skippedSlideTerm to "slide"
			set skippedIsAre to "is"
		else
			set skippedSlideTerm to "slides"
			set skippedIsAre to "are"
		end if
		if skippedCount is 0 then set skippedCount to "no"
		
		if useDocumentTheme is true then
			set speakString to "The current document, named “" & documentName & "”, " & booleanAsIsIsNot(playingStatus) & space & "playing" & "." & ¬
				silence500 & "It’s dimensions are " & documentWidth & " by " & documentHeight & ",  and is based on the “" & templateName & "” theme." & ¬
				silence500 & "It has " & slideCount & space & slideTerm & ", of which " & skippedCount & space & skippedSlideTerm & space & skippedIsAre & space & "skipped." & ¬
				silence500 & "The current slide is slide number" & space & currentSlideSlideNumber & ¬
				", and sllide numbers " & booleanAsAreAreNot(slideNumbersShowingStatus) & space & "showing" & ¬
				silence500 & documentSavedStatus
		else
			set speakString to "The current document, named “" & documentName & "”, " & booleanAsIsIsNot(playingStatus) & space & "playing" & "." & ¬
				silence500 & "And it’s dimensions are " & documentWidth & " by " & documentHeight & "." & ¬
				silence500 & "It has " & slideCount & space & slideTerm & ", of which " & skippedCount & space & skippedSlideTerm & space & skippedIsAre & space & "skipped." & ¬
				silence500 & "The current slide is slide number" & space & currentSlideSlideNumber & ¬
				", and sllide numbers " & booleanAsAreAreNot(slideNumbersShowingStatus) & space & "showing" & ¬
				silence500 & documentSavedStatus
		end if
		
		say speakString
	on error errorMessage number errorNumber
		return errorMessage
		my displaySpokenErrorAlert(errorMessage, "com.apple.iWork.Keynote")
		error number -128
	end try
end speakInfoAboutCurrentDocument

-- CURRENT SLIDE
on speakInfoAboutCurrentSlide()
	try
		tell application id "com.apple.iWork.Keynote"
			activate
			if not (exists document 1) then
				error "KEYNOTE_NO_DOCUMENT"
			end if
			tell front document
				tell «class crsl»
					set skippedStatus to «class Kskp» of it
					set masterSlideName to the name of «class smas» of it
					set slideNumber to «class KSdN» of it
					set titleShowingStatus to «class Ktsh» of it
					set bodyShowingStatus to «class Kbsh» of it
					set presenterNotes to «class ksnt» of it
					if presenterNotes is "" then
						set presenterNotesStatusString to "has no presenter notes"
					else
						set presenterNotesStatusString to "has presenter notes"
					end if
					set transitionProperties to «class strn» of it
					if (get «class xeft» of transitionProperties) is «constant tefftnil» then
						set transitionString to "No transition effect has been applied"
					else
						set transitionString to "A transition effect has been applied"
					end if
				end tell
			end tell
		end tell
		if skippedStatus is true then
			set spokenString to "The current slide is set to be skipped." & space & ¬
				silence250 & "It’s master slide is " & masterSlideName & "." & space & ¬
				silence250 & transitionString & "." & space & ¬
				silence250 & "The default slide title " & convertBooleanToShowingString(titleShowingStatus) & "." & space & ¬
				silence250 & "The default slide body " & convertBooleanToShowingString(bodyShowingStatus) & "." & space & ¬
				silence250 & "And, the slide " & presenterNotesStatusString & "."
		else
			set spokenString to "The current slide is slide number " & slideNumber & "." & space & ¬
				silence250 & "It’s master slide is " & masterSlideName & "." & space & ¬
				silence250 & transitionString & "." & space & ¬
				silence250 & "The default slide title " & convertBooleanToShowingString(titleShowingStatus) & "." & space & ¬
				silence250 & "The default slide body " & convertBooleanToShowingString(bodyShowingStatus) & "." & space & ¬
				silence250 & "And, the slide " & presenterNotesStatusString & "."
		end if
		say spokenString
	on error errorMessage number errorNumber
		my displaySpokenErrorAlert(errorMessage, "com.apple.iWork.Keynote")
		error number -128
	end try
end speakInfoAboutCurrentSlide

-- TRANSITION OF CURRENT SLIDE
on speakInfoAboutTransitionOfCurrentSlide()
	try
		tell application id "com.apple.iWork.Keynote"
			activate
			if not (exists document 1) then
				error "KEYNOTE_NO_DOCUMENT"
			end if
			tell front document
				tell «class crsl»
					set transitionProperties to «class strn» of it
					if («class xeft» of transitionProperties) is «constant tefftnil» then
						set noTransition to true
					else
						set noTransition to false
					end if
					set transitionEffect to («class xeft» of transitionProperties)
					set transitionEffect to (my convertTransitionEffectConstantToString(transitionEffect))
					set automaticTransition to «class xaut» of transitionProperties
					if automaticTransition is true then
						set transitionStartMethod to "automatically"
					else
						set transitionStartMethod to "on-click"
					end if
					set transitionDelay to «class xdly» of transitionProperties
					set transitionDuration to «class xdur» of transitionProperties
				end tell
			end tell
		end tell
		if noTransition is true then
			if automaticTransition is true then
				set statusString to "The current slide has no transition effect." & space & ¬
					"It is started " & transitionStartMethod & "." & space & ¬
					"After a delay of " & transitionDelay & space & "seconds" & "."
			else
				set statusString to "The current slide has no transition effect." & space & ¬
					"It is started " & transitionStartMethod & "."
			end if
		else
			if automaticTransition is true then
				set statusString to "The current slide transition effect is set to: " & transitionEffect & "." & space & ¬
					"With a durration of " & transitionDuration & space & "seconds" & ", " & ¬
					"And is started " & transitionStartMethod & "." & space & ¬
					"After a delay of " & transitionDelay & space & "seconds" & "."
				
			else
				set statusString to "The current slide transition effect is set to: " & transitionEffect & "." & space & ¬
					"It is started " & transitionStartMethod & "." & space & ¬
					"And the transition durration is " & transitionDuration & space & "seconds" & "."
			end if
		end if
		say statusString
	on error errorMessage number errorNumber
		spokenErrorAlert(errorMessage)
	end try
end speakInfoAboutTransitionOfCurrentSlide

on convertTransitionEffectConstantToString(thisTransitionEffect)
	tell application id "com.apple.iWork.Keynote"
		if thisTransitionEffect is «constant tefftnil» then
			return "no transition effect"
		else if thisTransitionEffect is «constant tefftmjv» then
			return "magic move"
		else if thisTransitionEffect is «constant tefftshm» then
			return "shimmer"
		else if thisTransitionEffect is «constant tefftspk» then
			return "sparkle"
		else if thisTransitionEffect is «constant tefftswg» then
			return "swing"
		else if thisTransitionEffect is «constant tefftocb» then
			return "object cube"
		else if thisTransitionEffect is «constant tefftofp» then
			return "object flip"
		else if thisTransitionEffect is «constant tefftopp» then
			return "object pop"
		else if thisTransitionEffect is «constant tefftoph» then
			return "object push"
		else if thisTransitionEffect is «constant tefftorv» then
			return "object revolve"
		else if thisTransitionEffect is «constant tefftozm» then
			return "object zoom"
		else if thisTransitionEffect is «constant tefftprs» then
			return "perspective"
		else if thisTransitionEffect is «constant tefftclo» then
			return "clothesline"
		else if thisTransitionEffect is «constant tefftcft» then
			return "confetti"
		else if thisTransitionEffect is «constant tefftdis» then
			return "dissolve"
		else if thisTransitionEffect is «constant tefftdrp» then
			return "drop"
		else if thisTransitionEffect is «constant tefftdpl» then
			return "droplet"
		else if thisTransitionEffect is «constant tefftftc» then
			return "fade through color"
		else if thisTransitionEffect is «constant tefftgrd» then
			return "grid"
		else if thisTransitionEffect is «constant tefftirs» then
			return "iris"
		else if thisTransitionEffect is «constant tefftmvi» then
			return "move in"
		else if thisTransitionEffect is «constant tefftpsh» then
			return "push"
		else if thisTransitionEffect is «constant tefftrvl» then
			return "reveal"
		else if thisTransitionEffect is «constant tefftswi» then
			return "switch"
		else if thisTransitionEffect is «constant tefftwpe» then
			return "wipe"
		else if thisTransitionEffect is «constant tefftbld» then
			return "blinds"
		else if thisTransitionEffect is «constant tefftcpl» then
			return "color planes"
		else if thisTransitionEffect is «constant tefftcub» then
			return "cube"
		else if thisTransitionEffect is «constant tefftdwy» then
			return "doorway"
		else if thisTransitionEffect is «constant tefftfal» then
			return "fall"
		else if thisTransitionEffect is «constant tefftfip» then
			return "flip"
		else if thisTransitionEffect is «constant tefftfop» then
			return "flop"
		else if thisTransitionEffect is «constant tefftmsc» then
			return "mosaic"
		else if thisTransitionEffect is «constant tefftpfl» then
			return "page flip"
		else if thisTransitionEffect is «constant tefftpvt» then
			return "pivot"
		else if thisTransitionEffect is «constant tefftrfl» then
			return "reflection"
		else if thisTransitionEffect is «constant tefftrev» then
			return "revolving door"
		else if thisTransitionEffect is «constant tefftscl» then
			return "scale"
		else if thisTransitionEffect is «constant tefftswp» then
			return "swap"
		else if thisTransitionEffect is «constant tefftsws» then
			return "swoosh"
		else if thisTransitionEffect is «constant teffttwl» then
			return "twirl"
		else if thisTransitionEffect is «constant teffttwi» then
			return "twist"
		else
			return "unknown"
		end if
	end tell
end convertTransitionEffectConstantToString

-- SLIDE ITEMS OF THE CURRENT SLIDE
on speakCountOfSlideItemClasses()
	try
		tell application id "com.apple.iWork.Keynote"
			activate
			if not (exists document 1) then
				error "KEYNOTE_NO_DOCUMENT"
			end if
			tell front document
				tell «class crsl»
					set itemList to {}
					set elementCount to the count of every «class fmti»
					set theseTextItems to every «class shtx»
					set textItemCount to the count of theseTextItems
					if textItemCount is not 0 then set the end of itemList to {"text item", textItemCount}
					set theseLines to every «class iWln»
					set lineItemCount to the count of theseLines
					if lineItemCount is not 0 then set the end of itemList to {"line", lineItemCount}
					set theseShapes to every «class sshp»
					set shapeCount to the count of theseShapes
					if shapeCount is not 0 then set the end of itemList to {"shape", shapeCount}
					set theseImages to every «class imag»
					set imageCount to the count of theseImages
					if imageCount is not 0 then set the end of itemList to {"image", imageCount}
					set theseMovies to every «class shmv»
					set movieCount to the count of theseMovies
					if movieCount is not 0 then set the end of itemList to {"movie", movieCount}
					set theseTables to every «class NmTb»
					set tableCount to the count of theseTables
					if tableCount is not 0 then set the end of itemList to {"table", tableCount}
					set theseCharts to every «class shct»
					set chartCount to the count of theseCharts
					if chartCount is not 0 then set the end of itemList to {"chart", chartCount}
				end tell
			end tell
		end tell
		set spokenString to "The current slide contains "
		if elementCount is 0 then
			set spokenString to spokenString & "no items."
		else
			set itemCount to the count of itemList
			repeat with i from 1 to the itemCount
				copy item i of itemList to {className, classCount}
				if i is 1 then
					set spokenString to spokenString & classCount & space & pluralizeThisNoun(className, classCount)
				else if i is itemCount then
					set spokenString to spokenString & ", " & silence250 & "and" & space & classCount & space & pluralizeThisNoun(className, classCount)
				else
					set spokenString to spokenString & ", " & silence250 & space & classCount & space & pluralizeThisNoun(className, classCount)
				end if
			end repeat
		end if
		tell current application
			say spokenString
		end tell
	on error errorMessage number errorNumber
		spokenErrorAlert(errorMessage)
	end try
end speakCountOfSlideItemClasses

-- ELEMENTS OF CURRENT SLIDE
on speakInfoAboutElementsOfCurrentSlide()
	try
		tell application id "com.apple.iWork.Keynote"
			activate
			if not (exists document 1) then
				error "KEYNOTE_NO_DOCUMENT"
			end if
		end tell
		tell application "System Events"
			tell process "Keynote"
				set mainWindow to first window whose subrole is "AXStandardWindow"
				tell mainWindow
					set scrollAreaCount to the count of scroll areas
					if scrollAreaCount is 3 then
						set i to 2
					else
						set i to 1
					end if
					set thisSlide to missing value
					--repeat with i from 1 to scrollAreaCount
					tell scroll area i
						try
							set thisSlide to (first UI element whose role is "AXLayoutArea")
							tell thisSlide
								set UIElements to every UI element
								set UIElementCount to the count of UIElements
								if UIElementCount is 0 then
									tell current application
										say "The current slide contains no layout items"
									end tell
								else
									if UIElementCount is 1 then
										set itemTerm to "item"
									else
										set itemTerm to "items"
									end if
									tell current application
										say "The current slide contains " & UIElementCount & space & itemTerm
										delay 0.5
									end tell
									repeat with q from 1 to the UIElementCount
										set thisUIELement to item q of UIElements
										set roleDescription to (role description of thisUIELement) as text
										set accessibilityDescription to (accessibility description of thisUIELement) as text
										if accessibilityDescription is "" or accessibilityDescription is missing value then
											set accessibilityDescription to "There is no description for this item."
										else
											set accessibilityDescription to "Description: " & silence250 & accessibilityDescription
										end if
										set helpString to (help of thisUIELement) as text
										tell current application
											say ("item " & q & " of " & UIElementCount & " is " & my determineAOrAn(roleDescription) & space & roleDescription)
											delay 0.25
											say accessibilityDescription
											delay 0.25
											say ("Specifics: " & silence500 & helpString)
											if q is not UIElementCount then
												delay 0.5
											end if
										end tell
									end repeat
								end if
							end tell
							--exit repeat
						end try
					end tell
					--end repeat
				end tell
			end tell
		end tell
	on error errorMessage number errorNumber
		spokenErrorAlert(errorMessage)
	end try
end speakInfoAboutElementsOfCurrentSlide

-- IMAGES OF CURRENT SLIDE
on speakInfoAboutImagesOfCurrentSlide()
	try
		tell application id "com.apple.iWork.Keynote"
			activate
			if not (exists document 1) then
				error "KEYNOTE_NO_DOCUMENT"
			end if
			tell front document
				tell «class crsl»
					set theseImages to every «class imag»
					set imageCount to the count of theseImages
					if imageCount is 0 then
						error "CURRENT_SLIDE_NO_IMAGES"
					end if
					set largestImage to my getLargestImage(theseImages)
					repeat with i from 1 to the imageCount
						set thisImage to «class imag» i
						if thisImage is largestImage then
							set isLargestImage to true
						else
							set isLargestImage to false
						end if
						tell thisImage
							set imageFilename to «class atfn» of it
							set imageDescription to «class dscr» of it
							set imageOpacity to «class pSOp» of it
							set imageRotation to «class siro» of it
							set imageReflectionShowing to «class sirs» of it
							set imageIsLocked to «class pLck» of it
							set imageHeight to «class sith» of it
							set imageWidth to «class sitw» of it
							set imagePostion to «class sipo» of it
						end tell
						tell current application
							if isLargestImage is true then
								set responseOpening to "Image" & space & i & space & "of" & space & imageCount & space & ", is the largest image." & silence500
							else
								set responseOpening to "Image" & space & i & space & "of" & space & imageCount & space & silence500
							end if
							if imageDescription is "" then
								set speakString to responseOpening & ¬
									"height: " & imageHeight & ", width: " & imageWidth & ", position: " & (item 1 of imagePostion) & " horizontal, " & (item 2 of imagePostion) & " vertical." & silence500 & "File name is “" & imageFilename & "”" & ", and this image has no description."
							else
								set speakString to responseOpening & ¬
									"height: " & imageHeight & ", width: " & imageWidth & ", position: " & (item 1 of imagePostion) & " horizontal, " & (item 2 of imagePostion) & " vertical." & silence500 & "File name is “" & imageFilename & "”" & ", and its description is:" & silence500 & imageDescription
							end if
							if imageRotation is not 0 then
								set speakString to speakString & silence500 & "Image rotation is " & imageRotation & " degrees."
							end if
							if imageOpacity is not 100 then
								set speakString to speakString & silence500 & "Image opacity is " & imageRotation & " percent."
							end if
							if imageReflectionShowing is true then
								set speakString to speakString & silence500 & "The image is showing a reflection."
							end if
							if imageIsLocked is true then
								set speakString to speakString & silence500 & "The image is locked."
							end if
							say speakString
							delay 0.75
						end tell
					end repeat
				end tell
			end tell
		end tell
	on error errorMessage number errorNumber
		my displaySpokenErrorAlert(errorMessage, "com.apple.iWork.Keynote")
		error number -128
	end try
end speakInfoAboutImagesOfCurrentSlide

on getLargestImage(theseImages)
	tell application id "com.apple.iWork.Keynote"
		set largestImage to missing value
		set largestVolume to 0
		repeat with i from 1 to the count of theseImages
			set thisImage to item i of theseImages
			set imageWidth to «class sitw» of thisImage
			set imageHeight to «class sith» of thisImage
			set imageVolume to imageWidth * imageHeight
			if imageVolume is greater than largestVolume then
				set largestVolume to imageVolume
				set largestImage to thisImage
			end if
		end repeat
		return largestImage
	end tell
end getLargestImage

-- SPEAK SLIDE TITLE
on speakContentOfVisibleDefaultTitleItem()
	try
		tell application id "com.apple.iWork.Keynote"
			activate
			if not (exists document 1) then
				error "KEYNOTE_NO_DOCUMENT"
			end if
			set isPlaying to «class Plng» of it
			tell front document
				tell «class crsl»
					if «class Ktsh» is false then
						error "SLIDE_TITLE_NOT_SHOWING"
					end if
					set titleText to the «class pDTx» of the «class sdti»
					if titleText is "" then error "NO_TITLE_TEXT"
				end tell
			end tell
		end tell
		tell current application
			my playTitleSound()
			say titleText
		end tell
		-- store the JXA call to this handler
		set JXACommandString to "Library('DC-Assistive-Keynote').speakContentOfVisibleDefaultTitleItem();"
		tell script "DC-Support" to storeJXACommandString(JXACommandString)
	on error errorMessage number errorNumber
		spokenErrorAlert(errorMessage)
		--my displaySpokenErrorAlert(errorMessage, "com.apple.iWork.Keynote")
		-- error number -128
	end try
end speakContentOfVisibleDefaultTitleItem

-- SPEAK SLIDE BODY
on speakContentOfVisibleDefaultBodyItem()
	try
		tell application id "com.apple.iWork.Keynote"
			activate
			if not (exists document 1) then
				error "KEYNOTE_NO_DOCUMENT"
			end if
			set isPlaying to «class Plng» of it
			tell front document
				tell «class crsl»
					if «class Kbsh» is false then
						error "SLIDE_BODY_NOT_SHOWING"
					end if
					set bodyText to the «class pDTx» of the «class sdbi»
					if bodyText is "" then error "NO_BODY_TEXT"
				end tell
			end tell
		end tell
		tell current application
			my playBodySound()
			my speakDelimitedParagraphs(bodyText, 0.5)
		end tell
		-- store the JXA call to this handler
		set JXACommandString to "Library('DC-Assistive-Keynote').speakContentOfVisibleDefaultBodyItem();"
		tell script "DC-Support" to storeJXACommandString(JXACommandString)
	on error errorMessage number errorNumber
		spokenErrorAlert(errorMessage)
	end try
end speakContentOfVisibleDefaultBodyItem

-- SPEAK SLIDE TITLE & BODY
on speakContentOfVisibleDefaultTextItems()
	try
		tell application id "com.apple.iWork.Keynote"
			activate
			if not (exists document 1) then
				error "KEYNOTE_NO_DOCUMENT"
			end if
			tell front document
				tell «class crsl»
					set titleShowing to «class Ktsh»
					set bodyShowing to «class Kbsh»
				end tell
			end tell
		end tell
		if titleShowing is false and bodyShowing is false then
			error "NO_ACTIVE_DEFAULT_TEXT_ITEMS"
		else
			speakContentOfVisibleDefaultTitleItem()
			speakContentOfVisibleDefaultBodyItem()
		end if
		-- store the JXA call to this handler
		set JXACommandString to "Library('DC-Assistive-Keynote').speakContentOfVisibleDefaultTextItems();"
		tell script "DC-Support" to storeJXACommandString(JXACommandString)
	on error errorMessage number errorNumber
		spokenErrorAlert(errorMessage)
		--my displaySpokenErrorAlert(errorMessage, "com.apple.iWork.Keynote")
		error number -128
	end try
end speakContentOfVisibleDefaultTextItems

on speakDelimitedParagraphs(thisText, pauseDuration)
	set theseParagraphs to every paragraph of thisText
	set paragraphCount to the count of theseParagraphs
	repeat with i from 1 to the paragraphCount
		set thisParagraph to item i of theseParagraphs
		say thisParagraph
		if i is not paragraphCount then
			delay pauseDuration
		end if
	end repeat
end speakDelimitedParagraphs

-- SPEAK THE TEXT IN THE ACTIVE TEXT BOX

on readTextInCurrentTextContainer()
	try
		tell application id "com.apple.iWork.Keynote"
			activate
			if not (exists document 1) then
				error "KEYNOTE_NO_DOCUMENT"
			end if
		end tell
		tell application "System Events"
			tell process "Keynote"
				set mainWindow to first window whose subrole is "AXStandardWindow"
				tell mainWindow
					set scrollAreaCount to the count of scroll areas
					if scrollAreaCount is 3 then
						set i to 2
					else
						set i to 1
					end if
					set thisSlide to missing value
					tell scroll area i
						try
							set thisSlide to (first UI element whose role is "AXLayoutArea")
							tell thisSlide
								set UIElements to every UI element
								set UIElementCount to the count of UIElements
								if UIElementCount is 0 then
									tell current application
										say "The current slide contains no layout items"
									end tell
								else
									set surroundingText to "This text container is empty."
									repeat with q from 1 to the UIElementCount
										set thisUIELement to item q of UIElements
										get properties of thisUIELement
										if selected of thisUIELement is true then
											set surroundingText to (get accessibility description of thisUIELement)
											exit repeat
										end if
									end repeat
								end if
							end tell
						end try
					end tell
				end tell
			end tell
		end tell
		if surroundingText begins with "Rectangle, Body, " then
			set surroundingText to text from (length of "Rectangle, Body, ") to -1 of surroundingText
		else if surroundingText begins with "Rectangle, Title, " then
			set surroundingText to text from (length of "Rectangle, Title, ") to -1 of surroundingText
		end if
		say surroundingText
		-- store the JXA call to this handler
		set JXACommandString to "Library('DC-Assistive-Keynote').readTextInCurrentTextContainer();"
		tell script "DC-Support" to storeJXACommandString(JXACommandString)
	on error errorMessage number errorNumber
		spokenErrorAlert(errorMessage)
	end try
end readTextInCurrentTextContainer

-- READ THE SLIDE

on readTextItemContentImageDescriptions()
	try
		tell application id "com.apple.iWork.Keynote"
			activate
			if not (exists document 1) then
				error "KEYNOTE_NO_DOCUMENT"
			end if
			set isPlaying to «class Plng» of it
			tell front document
				tell «class crsl»
					(*
					set theseImages to every image
					repeat with i from 1 to the count of theseImages
						set thisImage to item i of theseImages
						set thisDescription to the description of thisImage
						if thisDescription is not missing value and thisDescription is not "" then
							my playImageSound()
							tell current application
								say thisDescription with waiting until completion
							end tell
						end if
					end repeat
					*)
					if «class Ktsh» is true then
						set titleText to the «class pDTx» of the «class sdti»
						if titleText is not "" then
							my speakContentOfVisibleDefaultTitleItem()
						end if
					end if
					if «class Kbsh» is true then
						set bodyText to the «class pDTx» of the «class sdbi»
						if bodyText is not "" then
							my speakContentOfVisibleDefaultBodyItem()
						end if
					end if
					set theseImages to every «class imag»
					repeat with i from 1 to the count of theseImages
						set thisImage to item i of theseImages
						set thisDescription to the «class dscr» of thisImage
						if thisDescription is not missing value and thisDescription is not "" then
							my playImageSound()
							tell current application
								say thisDescription with waiting until completion
							end tell
						end if
					end repeat
					-- text items if no title or body showing (Quote master slide)
					if «class Ktsh» is false and «class Kbsh» is false then
						set textItemCount to the count of every «class shtx»
						repeat with i from 1 to textItemCount
							set thisText to the «class pDTx» of «class shtx» i
							if thisText is not "" then
								my playTextItemSound()
								tell current application
									say thisText with waiting until completion
								end tell
							end if
						end repeat
					end if
				end tell
			end tell
		end tell
		-- store the JXA call to this handler
		set JXACommandString to "Library('DC-Assistive-Keynote').readTextItemContentImageDescriptions();"
		tell script "DC-Support" to storeJXACommandString(JXACommandString)
	on error errorMessage number errorNumber
		spokenErrorAlert(errorMessage)
	end try
end readTextItemContentImageDescriptions

-- READ THE NEXT SLIDE

on readTheNextSlide()
	try
		tell application id "com.apple.iWork.Keynote"
			activate
			if not (exists document 1) then
				error "KEYNOTE_NO_DOCUMENT"
			end if
			set startingSlideNumber to the «class KSdN» of the «class crsl» of the front document
			tell front document
				set slideCount to the count of (every «class KnSd» whose «class Kskp» is false)
				tell «class crsl»
					set transitionProperties to «class strn» of it
					if («class xeft» of transitionProperties) is «constant tefftnil» then
						set delayDuration to 0.5
					else
						if («class xaut» of transitionProperties) is true then
							set delayDuration to («class xdur» of transitionProperties) + («class xdly» of transitionProperties) + 0.5
						else -- on click
							set delayDuration to («class xdur» of transitionProperties) + 0.5
						end if
					end if
				end tell
			end tell
			if «class Plng» is true then
				«event KntcsteF»
				tell current application to delay delayDuration
				set thisSlideNumber to the «class KSdN» of the «class crsl» of the front document
				if thisSlideNumber is startingSlideNumber then
					tell current application to beep
				else
					say ("Slide" & space & thisSlideNumber & space & "of" & space & slideCount & silence500)
					my readTextItemContentImageDescriptions()
				end if
			else
				error "NO_PLAYING_PRESENTATION"
			end if
		end tell
		-- store the JXA call to this handler
		set JXACommandString to "Library('DC-Assistive-Keynote').readTheNextSlide();"
		tell script "DC-Support" to storeJXACommandString(JXACommandString)
	on error errorMessage number errorNumber
		spokenErrorAlert(errorMessage)
	end try
end readTheNextSlide

(* LOCK *)

on lockAllTextItemsOnCurrentSlide()
	try
		tell application id "com.apple.iWork.Keynote"
			activate
			if not (exists document 1) then
				error "KEYNOTE_NO_DOCUMENT"
			end if
			tell front document
				tell «class crsl»
					set itemCount to the count of every «class shtx»
					set «class pLck» of every «class shtx» to true
				end tell
			end tell
		end tell
		if itemCount is not 0 then -- deselect the locked item
			tell application "System Events" to key code 53
		end if
		my playLockingSound()
		(*
		set itemTerm to pluralizeThisNoun("text item", itemCount)
		say (itemCount as text) & space & itemTerm & space & "locked"
		*)
	on error errorMessage number errorNumber
		spokenErrorAlert(errorMessage)
		error number -128
	end try
end lockAllTextItemsOnCurrentSlide

on unlockAllTextItemsOnCurrentSlide()
	try
		tell application id "com.apple.iWork.Keynote"
			activate
			if not (exists document 1) then
				error "KEYNOTE_NO_DOCUMENT"
			end if
			tell front document
				tell «class crsl»
					set itemCount to the count of every «class shtx»
					set «class pLck» of every «class shtx» to false
				end tell
			end tell
		end tell
		if itemCount is not 0 then -- deselect the locked item
			tell application "System Events" to key code 53
		end if
		my playUnlockingSound()
		(*
		set itemTerm to pluralizeThisNoun("text item", itemCount)
		say (itemCount as text) & space & itemTerm & space & "unlocked"
		*)
	on error errorMessage number errorNumber
		spokenErrorAlert(errorMessage)
	end try
end unlockAllTextItemsOnCurrentSlide

on lockDefaultTitleItemOnCurrentSlide()
	try
		tell application id "com.apple.iWork.Keynote"
			activate
			if not (exists document 1) then
				error "KEYNOTE_NO_DOCUMENT"
			end if
			tell front document
				tell «class crsl»
					if «class Ktsh» is true then
						set «class pLck» of «class sdti» to true
					else
						error "SLIDE_TITLE_NOT_SHOWING"
					end if
				end tell
			end tell
		end tell
		tell application "System Events" to key code 53
		my playLockingSound()
		(*
		tell current application
			say "title locked"
		end tell
		*)
	on error errorMessage number errorNumber
		spokenErrorAlert(errorMessage)
	end try
end lockDefaultTitleItemOnCurrentSlide

on lockDefaultBodyItemOnCurrentSlide()
	try
		tell application id "com.apple.iWork.Keynote"
			activate
			if not (exists document 1) then
				error "KEYNOTE_NO_DOCUMENT"
			end if
			tell front document
				tell «class crsl»
					if «class Kbsh» is true then
						set «class pLck» of «class sdbi» to true
					else
						error "SLIDE_BODY_NOT_SHOWING"
					end if
				end tell
			end tell
		end tell
		tell application "System Events" to key code 53
		my playLockingSound()
		(*
		tell current application
			say "body locked"
		end tell
		*)
	on error errorMessage number errorNumber
		spokenErrorAlert(errorMessage)
	end try
end lockDefaultBodyItemOnCurrentSlide

on unlockDefaultTitleItemOnCurrentSlide()
	try
		tell application id "com.apple.iWork.Keynote"
			activate
			if not (exists document 1) then
				error "KEYNOTE_NO_DOCUMENT"
			end if
			tell front document
				tell «class crsl»
					if «class Ktsh» is true then
						set «class pLck» of «class sdti» to false
					else
						error "SLIDE_TITLE_NOT_SHOWING"
					end if
				end tell
			end tell
		end tell
		tell application "System Events" to key code 53
		my playUnlockingSound()
		(*
		tell current application
			say "title locked"
		end tell
		*)
	on error errorMessage number errorNumber
		spokenErrorAlert(errorMessage)
		error number -128
	end try
end unlockDefaultTitleItemOnCurrentSlide

on unlockDefaultBodyItemOnCurrentSlide()
	try
		tell application id "com.apple.iWork.Keynote"
			activate
			if not (exists document 1) then
				error "KEYNOTE_NO_DOCUMENT"
			end if
			tell front document
				tell «class crsl»
					if «class Kbsh» is true then
						set «class pLck» of «class sdbi» to false
					else
						error "SLIDE_BODY_NOT_SHOWING"
					end if
				end tell
			end tell
		end tell
		tell application "System Events" to key code 53
		my playUnlockingSound()
		(*
		tell current application
			say "body locked"
		end tell
		*)
	on error errorMessage number errorNumber
		spokenErrorAlert(errorMessage)
		error number -128
	end try
end unlockDefaultBodyItemOnCurrentSlide

on ceaseEditAndLock()
	try
		tell application id "com.apple.iWork.Keynote"
			activate
			if not (exists document 1) then
				error "KEYNOTE_NO_DOCUMENT"
			end if
			tell front document
				tell «class crsl»
					set theseTextItems to every «class shtx»
					if theseTextItems is {} then error "NO_SELECTED_TEXT_ITEMS"
				end tell
			end tell
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
						repeat with i from 1 to the count of UI elements
							set thisLayoutItem to UI element i
							if selected of thisLayoutItem is true then
								keystroke "l" using command down
								delay 0.5
								key code 53
								exit repeat
							end if
						end repeat
					end tell
				end tell
			end tell
		end tell
		my playLockingSound()
	on error errorMessage number errorNumber
		spokenErrorAlert(errorMessage)
		error number -128
	end try
end ceaseEditAndLock

on playLockingSound()
	tell current application
		set libraryPath to the POSIX path of (path to me)
		set soundFilePath to libraryPath & "Contents/Resources/lockClosing.aif"
		do shell script ("afplay" & space & quoted form of soundFilePath)
	end tell
end playLockingSound

on playUnlockingSound()
	tell current application
		set libraryPath to the POSIX path of (path to me)
		set soundFilePath to libraryPath & "Contents/Resources/lockOpening.aif"
		do shell script ("afplay" & space & quoted form of soundFilePath)
	end tell
end playUnlockingSound

on playTitleSound()
	tell current application
		delay 0.5
		set libraryPath to the POSIX path of (path to me)
		set soundFilePath to libraryPath & "Contents/Resources/D-C3.m4a"
		do shell script ("afplay" & space & "-t" & space & soundDuration & space & "-v" & space & soundVolume & space & quoted form of soundFilePath)
	end tell
end playTitleSound

on playBodySound()
	tell current application
		delay 0.5
		set libraryPath to the POSIX path of (path to me)
		set soundFilePath to libraryPath & "Contents/Resources/G-C2.m4a"
		do shell script ("afplay" & space & "-t" & space & soundDuration & space & "-v" & space & soundVolume & space & quoted form of soundFilePath)
	end tell
end playBodySound

on playImageSound()
	tell current application
		delay 0.5
		set libraryPath to the POSIX path of (path to me)
		set soundFilePath to libraryPath & "Contents/Resources/F-C3.m4a"
		do shell script ("afplay" & space & "-t" & space & soundDuration & space & "-v" & space & soundVolume & space & quoted form of soundFilePath)
	end tell
end playImageSound

on playTextItemSound()
	tell current application
		delay 0.5
		set libraryPath to the POSIX path of (path to me)
		set soundFilePath to libraryPath & "Contents/Resources/C-C3.m4a"
		do shell script ("afplay" & space & "-t" & space & soundDuration & space & "-v" & space & soundVolume & space & quoted form of soundFilePath)
	end tell
end playTextItemSound

(* TITLE & DESCRIPTION PALETTE *)
on launchPresenterNotesApplet()
	set libraryPath to the POSIX path of (path to me)
	set helperAppletPath to libraryPath & "Contents/Resources/Keynote Notes Helper.app"
	do shell script "open " & quoted form of helperAppletPath
end launchPresenterNotesApplet



(* OPEN SAVE PANEL *)

on navigateOpenSavePanelToDocumentsFolder()
	set thisPath to the POSIX path of (path to documents folder)
	changeDisplayedDirectoryInOpenSavePanel("com.apple.iWork.Keynote", "Keynote", thisPath)
end navigateOpenSavePanelToDocumentsFolder

on navigateOpenSavePanelToPicturesFolder()
	set thisPath to the POSIX path of (path to pictures folder)
	changeDisplayedDirectoryInOpenSavePanel("com.apple.iWork.Keynote", "Keynote", thisPath)
end navigateOpenSavePanelToPicturesFolder

on navigateOpenSavePanelToMoviesFolder()
	set thisPath to the POSIX path of (path to movies folder)
	changeDisplayedDirectoryInOpenSavePanel("com.apple.iWork.Keynote", "Keynote", thisPath)
end navigateOpenSavePanelToMoviesFolder

on navigateOpenSavePanelToDesktopFolder()
	set thisPath to the POSIX path of (path to desktop folder)
	changeDisplayedDirectoryInOpenSavePanel("com.apple.iWork.Keynote", "Keynote", thisPath)
end navigateOpenSavePanelToDesktopFolder

on navigateOpenSavePanelToiCloudDrive()
	set thisPath to the POSIX path of (path to library folder from user domain)
	set thisPath to thisPath & "Mobile Documents/com~apple~CloudDocs"
	changeDisplayedDirectoryInOpenSavePanel("com.apple.iWork.Keynote", "Keynote", thisPath)
end navigateOpenSavePanelToiCloudDrive

on changeDisplayedDirectoryInOpenSavePanel(appID, processName, thisPath)
	tell application id appID
		activate
	end tell
	tell application "System Events"
		keystroke "g" using {command down, shift down}
		delay 1
		keystroke thisPath
		delay 0.5
		keystroke return
	end tell
end changeDisplayedDirectoryInOpenSavePanel


(* SUPPORT HANDLERS *)

on convertToNoForZero(thisValue)
	if thisValue is 0 then
		return "no"
	else
		return thisValue
	end if
end convertToNoForZero

on pluralizeThisNoun(thisString, thisValue)
	if thisValue is 1 then
		return thisString
	else
		return (thisString & "s")
	end if
end pluralizeThisNoun

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

on booleanAsIsIsNot(booleanValue)
	if booleanValue is true then
		return "is"
	else
		return "is not"
	end if
end booleanAsIsIsNot

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

