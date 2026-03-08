-- Turn on lights via HomeKit shortcut
-- App: Homepod
-- Usage: osascript scripts/workflows/homepod/homepod-lights-on.applescript
-- Requires: A Shortcut named "Lights On" that controls HomeKit lights

-- Concept: do shell script "shortcuts run 'Name'"
--   The Shortcuts CLI bridge: runs any Shortcut from AppleScript.
--   HomeKit accessories like smart lights can only be controlled via Shortcuts
--   from the command line — there is no direct AppleScript dictionary for Home.

try
	do shell script "shortcuts run 'Lights On'"
	display notification "Lights turned on" with title "HomePod"
on error errMsg
	display notification errMsg with title "HomePod Error"
end try
