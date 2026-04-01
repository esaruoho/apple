tell application "System Events"
	tell expose preferences
		-- SCREEN CORNERS (top right screen corner, bottom left screen corner, bottom right screen corner, top right screen corner)
		get the properties of the top right screen corner
		--> returns: {activity:show desktop, class:screen corner, modifiers:{}}
		set properties of the top right screen corner to {activity:show desktop, modifiers:{control, option}}
		
		-- EXPOSE SHORTCUTS
		get the properties of the all windows shortcut
		-- {class:shortcut, mouse button:4, function key:F9, function key modifiers:{}, mouse button modifiers:{}}
		get the properties of the application windows shortcut
		-- {class:shortcut, mouse button:0, function key:none, function key modifiers:{}, mouse button modifiers:{}}
		get the properties of the show desktop shortcut
		-- {class:shortcut, mouse button:0, function key:F11, function key modifiers:{}, mouse button modifiers:{}}
		
		-- DASHBOARD SHORTCUT
		get the properties of the dashboard shortcut
		-- {class:shortcut, mouse button:0, function key:none, function key modifiers:{}, mouse button modifiers:{}}
		
		-- SETTING A SHORTCUT
		set the properties of the application windows shortcut to {mouse button:3, function key:left control, function key modifiers:{none}, mouse button modifiers:{command}}
	end tell
end tell
