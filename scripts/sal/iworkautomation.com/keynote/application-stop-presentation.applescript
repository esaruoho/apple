-- IF KEYNOTE IS ACTIVE AND PLAYING THEN STOP IT
if running of application "Keynote" is true then
	tell application "Keynote"
		if playing is true then stop the front document
	end tell
end if
