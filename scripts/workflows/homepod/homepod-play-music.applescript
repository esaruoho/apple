-- Play music on HomePod via Shortcuts
-- App: Homepod
-- Usage: osascript scripts/workflows/homepod/homepod-play-music.applescript
-- Requires: A Shortcut named "Play Music" that targets HomePod

-- Concept: do shell script "shortcuts run 'Name'"
--   The Shortcuts CLI bridge: runs any Shortcut from AppleScript.
--   This lets you control HomeKit devices (like HomePod) from scripts,
--   because AppleScript can't talk to HomeKit directly — but Shortcuts can.

try
	do shell script "shortcuts run 'Play Music'"
	display notification "Music playing on HomePod" with title "HomePod"
on error errMsg
	display notification errMsg with title "HomePod Error"
end try
