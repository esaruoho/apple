use framework "Foundation"
use framework "AppKit"
use scripting additions

(* LOCATIONS *)

on showLocationTopAlbums()
	set URLString to "itms://itunes.apple.com/WebObjects/MZStore.woa/wa/viewTop?genreId=34&popId=11#11&app=itunes"
	openLocationIniTunes(URLString)
end showLocationTopAlbums

on showLocationTopSongs()
	set URLString to "itms://itunes.apple.com/WebObjects/MZStore.woa/wa/viewTop?genreId=34&id=1&popId=1&app=itunes"
	openLocationIniTunes(URLString)
end showLocationTopSongs

on showLocationTopMusicVideos()
	set URLString to "itms://itunes.apple.com/WebObjects/MZStore.woa/wa/viewTop?genreId=34&popId=5#5&app=itunes"
	openLocationIniTunes(URLString)
end showLocationTopMusicVideos

on showLocationTopMovies()
	set URLString to "itms://itunes.apple.com/WebObjects/MZStore.woa/wa/viewTop?genreId=33&id=39&popId=15&app=itunes"
	openLocationIniTunes(URLString)
end showLocationTopMovies

on showLocationTopFamilyMovies()
	set URLString to "itms://itunes.apple.com/WebObjects/MZStore.woa/wa/viewTop?genreId=4410&id=22033&popId=15&app=itunes"
	openLocationIniTunes(URLString)
end showLocationTopFamilyMovies



on openLocationIniTunes(URLString)
	tell application id "com.apple.iTunes"
		activate
		open location URLString
	end tell
end openLocationIniTunes

(* SUPPORT HANDLERS *)

on getIDOfFrontmostApplication()
	set aWorkspace to current application's NSWorkspace's sharedWorkspace
	set frontmostApp to aWorkspace's frontmostApplication
	set appID to (frontmostApp's bundleIdentifier) as text
	return appID
end getIDOfFrontmostApplication

on writeToFile(thisData, targetFile, appendData)
	tell current application
		try
			set the targetFile to the targetFile as string
			set the open_targetFile to open for access file targetFile with write permission
			if appendData is false then set eof of the open_targetFile to 0
			write thisData to the open_targetFile starting at eof
			close access the open_targetFile
			return true
		on error errorMessageString
			try
				close access file targetFile
			end try
			log ("ACTION ERROR: " & errorMessageString)
			return false
		end try
	end tell
end writeToFile

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

on announceCompletion()
	say my getLocalizedStringForKey("SUCCESSFUL_COMPLETION_PHRASE")
end announceCompletion

on logThis(thisText)
	if logEnabled then current application's NSLog("%@", thisText)
end logThis

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

