-- Set HomePod volume via dialog and Shortcuts
-- App: Homepod
-- Usage: osascript scripts/workflows/homepod/homepod-set-volume.applescript
-- Requires: A Shortcut named "Set HomePod Volume" that accepts volume level as input

-- Concept: do shell script "shortcuts run 'Name'"
--   The Shortcuts CLI bridge: runs any Shortcut from AppleScript.
--   This lets you control HomeKit devices (like HomePod) from scripts,
--   because AppleScript can't talk to HomeKit directly — but Shortcuts can.
-- Concept: display dialog "prompt" default answer "value"
--   Shows a dialog with a text input field. Returns a record with text returned.

try
	set volumeLevel to text returned of (display dialog "Set HomePod volume (0-100):" default answer "50")
	do shell script "echo " & quoted form of volumeLevel & " | shortcuts run 'Set HomePod Volume'"
	display notification "Volume set to " & volumeLevel with title "HomePod"
on error errMsg
	if errMsg does not contain "User canceled" then
		display notification errMsg with title "HomePod Error"
	end if
end try
