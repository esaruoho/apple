tell application "iTunes"
	tell the first library playlist
		get the duration of the last track
		--> returns: 281 (the length of the track in seconds)
	end tell
end tell

tell application "iTunes"
	tell the first library playlist
		get the artist of the last track
		--> returns: "Aaron Neville"
	end tell
end tell
