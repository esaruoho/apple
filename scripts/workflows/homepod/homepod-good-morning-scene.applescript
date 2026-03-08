-- Run the Good Morning HomeKit scene via Shortcuts
-- App: Homepod
-- Usage: osascript scripts/workflows/homepod/homepod-good-morning-scene.applescript
-- Requires: A Shortcut named "Good Morning" that triggers a HomeKit scene

-- Concept: do shell script "shortcuts run 'Name'"
--   The Shortcuts CLI bridge: runs any Shortcut from AppleScript.
--   HomeKit scenes coordinate multiple accessories at once — lights, thermostat,
--   music — and Shortcuts is the only way to trigger them programmatically.

try
	do shell script "shortcuts run 'Good Morning'"
	display notification "Good Morning scene activated" with title "HomePod"
on error errMsg
	display notification errMsg with title "HomePod Error"
end try
