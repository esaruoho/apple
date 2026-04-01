tell application "Keynote"
	activate
	if not (exists document 1) then error number -128
	set the playbackMethods to {"normal", "loop", "loop back and forth"}
	set thisValue to ¬
		choose from list playbackMethods with prompt ¬
			"Set the playback method of every audio clip to:"
	if thisValue is false then error number -128
	tell the front document
		if thisValue is {"normal"} then
			set repetition method of ¬
				every audio clip of every slide to none
		else if thisValue is {"loop"} then
			set repetition method of ¬
				every audio clip of every slide to loop
		else
			set repetition method of ¬
				every audio clip of every slide to loop back and forth
		end if
	end tell
end tell
