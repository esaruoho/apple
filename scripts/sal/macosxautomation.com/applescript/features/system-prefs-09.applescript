tell application "System Events"
	-- SET DESKTOP TO SPECIFIC PICTURE
	tell current desktop
		set picture rotation to 0 -- (0=off, 1=interval, 2=login, 3=sleep)
		set picture to file "Mac OS X:Library:Desktop Pictures:Plants:Agave.jpg"
	end tell
end tell
