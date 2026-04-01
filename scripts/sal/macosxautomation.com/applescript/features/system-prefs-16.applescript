tell application "System Events"
	tell network preferences
		get properties
		--> returns: {current location:location id "51BD3FB7-50D1-4859-9649-9138E7FF1ECA" of network preferences, class:network preferences object}
		get the name of every location
		--> returns: {"Automatic", "Sprint Card"}
		set current location to location "Automatic"
	end tell
end tell
