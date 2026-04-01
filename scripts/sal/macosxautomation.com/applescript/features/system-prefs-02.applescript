-- OPEN SYSTEM PREFERENCES TO THE SPACES PANE
tell application "System Preferences"
	activate
	set the current pane to pane id "com.apple.preference.expose"
	get the name of every anchor of pane id "com.apple.preference.expose"
	--> returns: {"Main", "Spaces"}
	reveal anchor "Spaces" of pane id "com.apple.preference.expose"
end tell
