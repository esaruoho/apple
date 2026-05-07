use AppleScript version "2.5"
use framework "Foundation"
use framework "AppKit"
use framework "EventKit"
use framework "CoreImage"
use framework "MapKit"
use framework "CoreLocation"
use framework "AddressBook"
use framework "CoreGraphics"
use scripting additions



(* CAPTURE MAP CLIPBOARD TO KEYNOTE *)
on exportMapClipboardToNewKeynoteSlide()
	set exportFormat to "PNG"
	try
		tell application "Maps"
			activate
			if the (count of windows) is 0 then error number -128
			set thisID to id of window 1
			copy the bounds of window 1 to {x, y, x1, y1}
			set imageWidth to x1 - x
			set imageHeight to y1 - y - 38 -- height of window toolbar
			-- clear the clipboard
			set the clipboard to "placeholder text"
			-- copy the Map to the clipboard
			tell application "System Events"
				keystroke "c" using command down
				delay 1
			end tell
			-- check to see that copy worked
			if (clipboard info for «class PNGf») is {} then
				tell application "System Events"
					keystroke tab
					delay 0.5
					keystroke "c" using command down
					delay 1
				end tell
			end if
			-- write the clipboard image data to file
			if exportFormat is "TIFF" then
				if (clipboard info for TIFF picture) is not {} then
					set thisImageData to get the clipboard as TIFF picture
					set aUUID to (current application's NSUUID's UUID()'s UUIDString) as string
					set targetPath to "~/Desktop/" & aUUID & ".tif"
					set targetPath to current application's NSString's stringWithString:targetPath
					set targetPath to (targetPath's stringByExpandingTildeInPath) as string
					set targetFile to targetPath as POSIX file
					set result to my writeImageDataToFile(thisImageData, targetFile, false)
					if result is false then
						error "Problem writing file."
					end if
				else
					error "No TIFF data on the clipboard."
				end if
			else
				if (clipboard info for «class PNGf») is not {} then
					set thisImageData to get the clipboard as «class PNGf»
					set aUUID to (current application's NSUUID's UUID()'s UUIDString) as string
					set targetPath to "~/Desktop/" & aUUID & ".png"
					set targetPath to current application's NSString's stringWithString:targetPath
					set targetPath to (targetPath's stringByExpandingTildeInPath) as string
					set targetFile to targetPath as POSIX file
					set result to my writeImageDataToFile(thisImageData, targetFile, false)
					if result is false then
						error "Problem writing file."
					end if
				else
					-- error "No PNG data on the clipboard."
					my exportMapWindowCaptureToNewKeynoteSlide()
				end if
			end if
		end tell
	on error errorMessage number errorNumber
		if errorNumber is not -128 then
			my displaySpokenErrorAlert(errorMessage, "com.apple.Maps")
		end if
		error number -128
	end try
	
	try
		tell application "Keynote Creator Studio"
			activate
			if not (exists document 1) then
				set thisDocument to make new document
			else if the (count of documents) is not 1 then
				set documentNames to the name of every document
				set dialogPrompt to my getLocalizedStringForKey("CHOOSE_DOCUMENT_FOR_MAP_ADD")
				set chosenDocument to (choose from list documentNames with prompt dialogPrompt)
				if chosenDocument is false then error number -128
				set chosenDocument to chosenDocument as string
				set thisDocument to the first document whose name is chosenDocument
			else
				set thisDocument to document 1
			end if
			tell thisDocument
				set documentWidth to width of it
				set documentHeight to height of it
				
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
				
				set currentSlide to get current slide of it
				set localizedWordForBlank to my getLocalizedStringForKey("LOCALIZED_WORD_FOR_BLANK")
				set newSlide to make new slide at after currentSlide with properties {base layout:slide layout localizedWordForBlank}
				
				tell newSlide
					set thisImage to make new image with properties ¬
						{file:targetFile ¬
							, width:newImageWidth ¬
							, height:newImageHeight ¬
							, position:{horizontalOffset, verticalOffset}}
				end tell
				
				-- move the export folder containing the imported items to the trash
				set fileManager to current application's NSFileManager's defaultManager()
				--set thisPOSIXPath to current application's NSString's stringWithString:windowCaptureFilePath
				--set pathOfFolderToDelete to thisPOSIXPath's stringByDeletingLastPathComponent()
				set resultingURL to missing value
				set URLOfItemToTrash to (current application's |NSURL|'s fileURLWithPath:targetPath)
				(fileManager's trashItemAtURL:URLOfItemToTrash resultingItemURL:resultingURL |error|:(missing value))
			end tell
		end tell
	on error errorMessage number errorNumber
		if errorNumber is not -128 then
			my displaySpokenErrorAlert(errorMessage, "com.apple.iWork.Keynote")
		end if
		error number -128
	end try
end exportMapClipboardToNewKeynoteSlide

(* CAPTURE MAP WINDOW TO KEYNOTE *)

on exportMapWindowCaptureToNewKeynoteSlide()
	tell application "Maps"
		activate
		if the (count of windows) is 0 then error number -128
		set thisID to id of window 1
		copy the bounds of window 1 to {x, y, imageWidth, imageHeight}
	end tell
	tell current application
		set pathToPicturesFolder to the POSIX path of (path to the pictures folder)
		set windowCaptureFilePath to pathToPicturesFolder & "map-window.png"
		
		
		(* set the capture to begin after 3 seconds and to capture just the window (no shadow) *)
		-- set commandString to "screencapture" & space & "-T" & space & 3 & space & "-ao" & space & "-l" & space & thisID & space & (quoted form of windowCaptureFilePath)
		-- my playScreenCaptureAudio()
		-- my playShutterSound()
		
		(* use this command string if you don't want to wait *)
		set commandString to "screencapture" & space & "-ao" & space & "-l" & space & thisID & space & (quoted form of windowCaptureFilePath)
		
		do shell script commandString
	end tell
	tell application "Keynote Creator Studio"
		activate
		if not (exists document 1) then
			set thisDocument to make new document
		else if the (count of documents) is not 1 then
			set documentNames to the name of every document
			set chosenDocument to (choose from list documentNames with prompt "Pick the document to add the image to:")
			if chosenDocument is false then error number -128
			set chosenDocument to chosenDocument as string
			set thisDocument to the first document whose name is chosenDocument
		else
			set thisDocument to document 1
		end if
		tell thisDocument
			set documentWidth to width of it
			set documentHeight to height of it
			
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
			
			set newSlide to make new slide with properties {base layout:slide layout "Blank"}
			
			tell newSlide
				set thisImage to make new image with properties ¬
					{file:(windowCaptureFilePath as POSIX file) ¬
						, width:newImageWidth ¬
						, height:newImageHeight ¬
						, position:{horizontalOffset, verticalOffset}}
			end tell
			
			-- move the export folder containing the imported items to the trash
			set fileManager to current application's NSFileManager's defaultManager()
			--set thisPOSIXPath to current application's NSString's stringWithString:windowCaptureFilePath
			--set pathOfFolderToDelete to thisPOSIXPath's stringByDeletingLastPathComponent()
			set resultingURL to missing value
			set URLOfItemToTrash to (current application's |NSURL|'s fileURLWithPath:windowCaptureFilePath)
			(fileManager's trashItemAtURL:URLOfItemToTrash resultingItemURL:resultingURL |error|:(missing value))
		end tell
	end tell
end exportMapWindowCaptureToNewKeynoteSlide

(* SUPPORT HANDLERS *)

on writeImageDataToFile(thisData, targetFile, appendData)
	try
		set the open_targetFile to open for access targetFile with write permission
		if appendData is false then set eof of the open_targetFile to 0
		write thisData to the open_targetFile starting at eof --as «class PNGf»
		close access the open_targetFile
		return true
	on error errorMessage
		log errorMessage
		try
			close access file targetFile
		end try
		return false
	end try
end writeImageDataToFile

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

on playScreenCaptureAudio()
	set thisBundlePOSIXPath to POSIX path of (path to me)
	set ResourcesFolderPath to thisBundlePOSIXPath & "Contents/Resources/"
	set beepSnd to quoted form of (ResourcesFolderPath & "IKBeep.aiff")
	--log beepSnd
	set timerDoneSnd to quoted form of (ResourcesFolderPath & "TimerDone.snd")
	--log timerDoneSnd
	set shutterSnd to quoted form of (ResourcesFolderPath & "cameraShutter.aiff")
	--log shutterSnd
	repeat 3 times
		do shell script "afplay -t 0.3 " & beepSnd
	end repeat
	-- do shell script "afplay  -t 0.5 -v 0.8 " & timerDoneSnd
	--do shell script "afplay -v 1.5 " & shutterSnd
	return true
end playScreenCaptureAudio

on playShutterSound()
	set thisBundlePOSIXPath to POSIX path of (path to me)
	set ResourcesFolderPath to thisBundlePOSIXPath & "Contents/Resources/"
	set shutterSnd to quoted form of (ResourcesFolderPath & "cameraShutter.aiff")
	do shell script "afplay -v 1.5 " & shutterSnd
	return true
end playShutterSound

on getLocalizedStringForKey(thisKey)
	set thisBundlePath to (path to me)
	return (localized string thisKey in bundle thisBundlePath)
end getLocalizedStringForKey

