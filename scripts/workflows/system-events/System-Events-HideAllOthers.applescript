-- Hide All Others (native, no keystroke simulation)
-- Hides every app except the frontmost one.
-- Works even with apps like Telegram that don't support ⌥⌘H.
-- Loupedeck: osascript /Users/esaruoho/work/apple/scripts/workflows/system-events/System-Events-HideAllOthers.applescript

tell application "System Events"
	set visible of every process whose frontmost is false to false
end tell
