tell application "System Events"
	tell security preferences
		get properties
		--> returns: {require password to wake:false, class:security preferences object, secure virtual memory:false, require password to unlock:false, automatic login:false, log out when inactive:false, log out when inactive interval:60}
		set properties to {require password to wake:false, secure virtual memory:false, require password to unlock:false, automatic login:false, log out when inactive:false, log out when inactive interval:60}
	end tell
end tell
