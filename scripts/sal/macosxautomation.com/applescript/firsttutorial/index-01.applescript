-- SETUP
tell application "Finder" to close every window

tell application "Finder" to open the startup disk

-- NAME PROPERTY
tell application "Finder" to get the name of the front Finder window

tell application "Finder" to close Finder window "Macintosh HD"

-- INDEX PROPERTY
tell application "Finder" to open the startup disk

tell application "Finder" to get the index of Finder window "Macintosh HD"

tell application "Finder" to open home

tell application "Finder" to get the index of Finder window "Macintosh HD"

tell application "Finder" to get the name of Finder window 1

tell application "Finder" to get the name of Finder window 2

tell application "Finder" to get the index of the first Finder window

tell application "Finder" to get the index of the second Finder window

tell application "Finder" to get the index of the 1st Finder window

tell application "Finder" to get the index of the 2nd Finder window

tell application "Finder" to get the index of the front Finder window

tell application "Finder" to get the index of the back Finder window

tell application "Finder" to get the index of the last Finder window

tell application "Finder" to get the index of the Finder window before the last Finder window

tell application "Finder" to get the index of the Finder window after the front Finder window

-- INDEX (set)
tell application "Finder" to set the index of the last Finder window to 1

tell application "Finder" to set the index of the last Finder window to the index of the first Finder window

-- TARGET
tell application "Finder" to get the target of the front Finder window

tell application "Finder" to set the target of the front Finder window to the startup disk

tell application "Finder" to set the target of the last Finder window to home

tell application "Finder" to set the target of the front Finder window to folder "Smith Project" of folder "Documents" of home

tell application "Finder" to set the target of the front Finder window to the startup disk

-- TOOLBAR VISIBLE
tell application "Finder" to get toolbar visible of the front Finder window

tell application "Finder" to set toolbar visible of the front Finder window to false

tell application "Finder" to set toolbar visible of the front Finder window to true

-- STATUS BAR VISIBLE
tell application "Finder" to set toolbar visible of the front Finder window to false

tell application "Finder" to set statusbar visible of the front Finder window to true

tell application "Finder" to set toolbar visible of the front Finder window to true

-- SIDEBAR WIDTH
tell application "Finder" to set the sidebar width of the front Finder window to 0

tell application "Finder" to set the sidebar width of the second Finder window to 0

tell application "Finder" to set the sidebar width of every Finder window to 128

tell application "Finder" to set the sidebar width of Finder window 2 to the sidebar width of Finder window 1

-- CURRENT VIEW 
tell application "Finder" to get the current view of the front Finder window

tell application "Finder" to set the current view of the front Finder window to list view

tell application "Finder" to set the current view of the front Finder window to column view

tell application "Finder" to set the current view of the front Finder window to icon view

tell application "Finder" to set the current view of the front Finder window to flow view

tell application "Finder" to set the current view of the window of every folder of home to icon view

-- POSITION
tell application "Finder" to get the position of the front Finder window

tell application "Finder" to set the position of the front Finder window to {94, 134}

tell application "Finder" to set the position of the front Finder window to {300, 134}

tell application "Finder" to set the position of the front Finder window to {300, 240}

-- BOUNDS PROPERTY
tell application "Finder" to get the bounds of the front Finder window

tell application "Finder" to set the bounds of the front Finder window to {24, 96, 524, 396}

tell application "Finder" to get the bounds of the window of the desktop

-- VERBS
tell application "Finder" to select the last Finder window

tell application "Finder" to set the index of the last Finder window to 1

-- TELL BLOCK
tell application "Finder" to close every window
tell application "Finder" to open home
tell application "Finder" to set toolbar visible of the front Finder window to true
tell application "Finder" to set the sidebar width of the front Finder window to 135
tell application "Finder" to set the current view of the front Finder window to column view
tell application "Finder" to set the bounds of the front Finder window to {36, 116, 511, 674}
tell application "Finder" to open folder "Documents" of home
tell application "Finder" to set toolbar visible of the front Finder window to false
tell application "Finder" to set statusbar visible of the front Finder window to true
tell application "Finder" to set the current view of the front Finder window to flow view
tell application "Finder" to set the bounds of the front Finder window to {528, 116, 1016, 674}
tell application "Finder" to select the last Finder window

tell application "Finder"
	close every window
	open home
	set toolbar visible of the front Finder window to true
	set the sidebar width of the front Finder window to 135
	set the current view of the front Finder window to column view
	set the bounds of the front Finder window to {36, 116, 511, 674}
	open folder "Documents" of home
	set toolbar visible of the front Finder window to false
	set the current view of the front Finder window to flow view
	set the bounds of front Finder window to {528, 116, 1016, 674}
	select the last Finder window
end tell

tell application "Finder"
	close every window
	open home
	tell the front Finder window
		set toolbar visible to true
		set the sidebar width to 135
		set the current view to column view
		set the bounds to {36, 116, 511, 674}
	end tell
	open folder "Documents" of home
	tell the front Finder window
		set toolbar visible to false
		set the current view to flow view
		set the bounds to {528, 116, 1016, 674}
	end tell
	select the last Finder window
end tell

-- SAFARI
tell application "Safari" to close every window

tell application "Safari" to open location "http://sal.local/~sal/Apple-AppleScript/"

tell application "Safari" to get the position of the front window

tell application "Safari" to get the bounds of window 1

tell application "Safari" to set the bounds of the front window to {0, 22, 800, 1024}

tell application "Finder" to get the bounds of the window of the desktop
tell application "Safari" to set the bounds of the front window to {0, 22, (3rd item of the result), (4th item of the result)}

-- QUICKTIME PLAYER
tell application "QuickTime Player" to get the name of the front document

tell application "QuickTime Player" to get the duration of the front document

tell application "QuickTime Player" to set the current time of the front document to 94900

tell application "QuickTime Player" to play the front document

tell application "QuickTime Player" to stop the front document

-- ITUNES
tell application "iTunes" to get the name of the last track of the first library playlist

tell application "iTunes" to get the duration of the last track of the first library playlist

tell application "iTunes" to get the artist of the first track of the first library playlist

tell application "iTunes" to play the first track of the first library playlist

tell application "iTunes" to stop
