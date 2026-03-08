-- Open System Settings Privacy & Security pane via Accessibility API
-- Tier 8: Accessibility API — reaches apps with zero AppleScript support
-- Usage: osascript scripts/workflows/accessibility/ax-system-settings-privacy.applescript

-- Concept: Accessibility API (AX)
--   Uses System Events to click UI elements by their accessibility hierarchy.
--   Requires Accessibility permission in System Settings > Privacy & Security.

tell application "System Settings"
	activate
	delay 1
end tell
tell application "System Events"
	tell process "System Settings"
		try
			click button "Privacy & Security" of group 1 of scroll area 1 of group 1 of splitter group 1 of group 1 of window 1
		on error
			-- Fallback: use URL scheme if AX hierarchy has changed
			do shell script "open 'x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension'"
		end try
	end tell
end tell
