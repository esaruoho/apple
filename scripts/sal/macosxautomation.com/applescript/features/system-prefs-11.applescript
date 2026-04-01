tell application "System Events"
	tell dock preferences
		get properties
		--> returns: {minimize effect:genie, springing delay:1.0, dock size:0.428571432829, magnification:false, springing:false, location:bottom, class:dock preferences object, magnification size:1.0, animate:true, autohide:false}
		set properties to {minimize effect:scale, location:right, autohide:true, magnification:false, magnification size:0.5, dock size:1.0}
	end tell
end tell
