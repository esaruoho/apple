tell application "System Events"
	-- RANDOM ROTATION OF A FOLDER OF IMAGES
	tell current desktop
		set picture rotation to 1 -- (0=off, 1=interval, 2=login, 3=sleep)
		set random order to true
		set pictures folder to file "Mac OS X:Library:Desktop Pictures:Plants:"
		set change interval to 5.0 -- seconds
	end tell
end tell
