tell application "Keynote"
	activate
	tell front document
		set startingSlide to current slide
		repeat
			duplicate (get current slide)
			tell the last slide
				set slideText to object text of the default title item
				-- get the minutes and seconds
				if slideText begins with ":" then
					set amountInMinutes to "0"
					set amountInSeconds to first word of slideText
				else
					set amountInMinutes to first word of slideText
					set amountInSeconds to second word of slideText
				end if
				-- adjust seconds
				if amountInSeconds is "00" then
					set newSeconds to "59"
					-- adjust minutes
					if amountInMinutes is "0" then
						set newMinutes to ""
					else
						set newMinutes to ¬
							((amountInMinutes as integer) - 1) as string
						if newMinutes is "0" then set newMinutes to ""
					end if
				else
					set newSeconds to ¬
						((amountInSeconds as integer) - 1) as string
					if length of newSeconds is 1 then
						set newSeconds to "0" & newSeconds
					end if
					-- adjust minutes
					if amountInMinutes is "0" then
						set newMinutes to ""
					else
						set newMinutes to amountInMinutes
					end if
				end if
				-- set the text
				set newTime to newMinutes & ":" & newSeconds
				set object text of the default title item to newTime
				if newTime is ":00" then exit repeat
			end tell
		end repeat
		-- set the transition of all slides
		set the transition properties of every slide to {transition effect:no transition effect, transition duration:0, transition delay:1, automatic transition:true}
	end tell
	-- start the presentation
	start front document from startingSlide
end tell
