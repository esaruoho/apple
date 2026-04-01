tell application "System Events"
	-- GET DESKTOP PICTURE SETTINGS
	tell current desktop
		get properties
		--> returns: {display name:"Color LCD", random order:false, pictures folder:file "Mac OS X:Library:Desktop Pictures:", picture rotation:0, class:desktop, change interval:60.0, picture:file "Mac OS X:Library:Desktop Pictures:Aqua Blue.jpg"}
	end tell
end tell
