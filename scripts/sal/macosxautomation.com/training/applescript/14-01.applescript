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
