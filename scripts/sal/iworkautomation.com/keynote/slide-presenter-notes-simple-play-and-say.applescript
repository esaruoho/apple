property defaultSlideDuraton : 2
property pauseBeforeSpeaking : 0 -- 1.5
property stoppingStatement : "[[slnc 1000]] Stopping presentation."

tell application "Keynote"
	activate
	try
		if not (exists document 1) then error number -128
		
		if playing is true then stop the front document
		
		tell document 1
			set the slideCount to the count of (slides whose skipped is false)
			start from (first slide whose slide number is 1)
		end tell
		repeat with i from 1 to the slideCount
			log i
			if playing is false then
				my speakSlideNotes(stoppingStatement)
				error number -128
			end if
			tell document 1
				repeat
					set currentSlideNumber to (get slide number of current slide)
					if currentSlideNumber is equal to i then exit repeat
					my idleForThisTime(1)
					if my playingStatus() is false then
						my speakSlideNotes(stoppingStatement)
						error number -128
					end if
				end repeat
				set thisSlidesPresenterNotes to presenter notes of current slide
			end tell
			if thisSlidesPresenterNotes is "" then
				delay defaultSlideDuraton
			else
				if pauseBeforeSpeaking is not 0 then
					delay pauseBeforeSpeaking
				end if
				my speakSlideNotes(thisSlidesPresenterNotes)
			end if
			if i is slideCount then
				exit repeat
			else
				if playing is false then
					my speakSlideNotes(stoppingStatement)
					error number -128
				end if
				show next
			end if
		end repeat
		
		tell document 1 to stop
	on error errorMessage number errorNumber
		if errorNumber is not -128 then
			display alert (("ERROR " & errorNumber) as string) message errorMessage
		end if
	end try
end tell

on speakSlideNotes(thisSlidesPresenterNotes)
	say thisSlidesPresenterNotes with waiting until completion
end speakSlideNotes

on idleForThisTime(idleTimeInSeconds)
	do shell script "sleep " & (idleTimeInSeconds as string)
end idleForThisTime

on playingStatus()
	tell application "Keynote"
		return (get playing)
	end tell
end playingStatus
