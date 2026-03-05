-- Start Dictation AppleScript
-- Triggers dictation in the frontmost application

delay 1.5 -- Wait for Claude to initialize
tell application "System Events"
    tell process "Terminal"
        click menu item "Start Dictation" of menu "Edit" of menu bar 1
    end tell
end tell
