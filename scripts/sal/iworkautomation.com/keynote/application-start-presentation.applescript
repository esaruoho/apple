-- IF KEYNOTE IS ACTIVE AND NOT PLAYING THEN START IT
if running of application "Keynote" is true then
	tell application "Keynote"
		activate
		try
			if playing is false then start the front document
		end try
	end tell
end if
