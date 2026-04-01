tell application "Finder" to get the bounds of the window of the desktop
tell application "Safari" to set the bounds of the front window to {0, 22, (3rd item of the result), (4th item of the result)}
