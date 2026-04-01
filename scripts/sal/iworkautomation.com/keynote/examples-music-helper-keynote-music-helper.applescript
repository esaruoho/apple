property idleTimeInSeconds : 1

global playlistTitle, hasPlayed, startFlag

on run
	if running of application "iTunes" is false then
		tell application "iTunes" to launch
	end if
	tell application "iTunes"
		set thesePlaylistTitles to the name of every user playlist
	end tell
	activate
	set the beginning of thesePlaylistTitles to "USE MUSIC LIBRARY"
	set chosenPlaylistTitle to ¬
		(choose from list thesePlaylistTitles with prompt "Choose the playlist to use:")
	if chosenPlaylistTitle is false then tell me to quit
	set chosenPlaylistTitle to chosenPlaylistTitle as string
	if chosenPlaylistTitle is "USE MUSIC LIBRARY" then
		set playlistTitle to missing value
	else
		set playlistTitle to chosenPlaylistTitle
	end if
	set hasPlayed to false
	display dialog "Applet is active and ready for presentation to begin!" buttons {"Switch to Keynote", "OK"} default button 2
	if button returned of the result is "Switch to Keynote" then
		tell application "Keynote"
			activate
		end tell
		set startFlag to true
	else
		set startFlag to false
	end if
end run

on idle
	if startFlag is true then
		set startFlag to false
		return 1
	end if
	if running of application "Keynote" is true then
		tell application "Keynote"
			if playing is true then
				activate
				set hasPlayed to true
				set trackTitle to the presenter notes of current slide of front document
				if trackTitle is "" then
					my stopPlaying()
				else
					my playThisTrack(trackTitle, missing value)
				end if
			else
				-- stop iTunes if it playing
				my stopPlaying()
				-- quit the applet if the presentation has been played
				if hasPlayed is true then
					tell me to quit
				end if
			end if
		end tell
	else
		say "Keynote is not open. Quiting applet."
		tell me to quit
	end if
	if running of application "iTunes" is false then
		say "iTunes is not open. Quiting applet."
		tell me to quit
	end if
	return idleTimeInSeconds
end idle

on playThisTrack(trackTitle, playlistTitle)
	-- check to see if iTunes is open
	if running of application "iTunes" is true then
		try
			tell application "iTunes"
				-- check to see if iTunes is playing
				if player state is playing then
					-- if the current track is not the current track then play new track
					if the name of current track is not trackTitle then
						if playlistTitle is missing value then
							tell user playlist "Music"
								play (first track whose name is trackTitle)
							end tell
						else
							if exists user playlist playlistTitle then
								tell user playlist playlistTitle
									play (first track whose name is trackTitle)
								end tell
							else
								say "No matching playlist in iTunes. Quitting applet."
								tell me to quit
							end if
						end if
					end if
				else
					-- play new track
					tell user playlist "Music"
						play (first track whose name is trackTitle)
					end tell
				end if
			end tell
			return true
		on error errorMessage number errorNumber
			if errorNumber is -1728 then
				-- no matching track
				say "No matching track in the iTunes music library."
			else
				-- do nothing
			end if
			return false
		end try
	else
		say "iTunes is not running"
		return false
	end if
end playThisTrack

on stopPlaying()
	if running of application "iTunes" is true then
		tell application "iTunes"
			if player state is playing then stop
		end tell
	end if
end stopPlaying

on quit
	continue quit
end quit
