-- Set macOS accessibility audio to play stereo audio as mono or stereo
-- Triggers: mono, stereo, audio, accessibility, ax, system, settings, play stereo audio as mono
-- Category: Accessibility
-- Tier 8: Accessibility API — reaches System Settings accessibility audio pane
-- Usage: osascript scripts/workflows/accessibility/ax-system-settings-mono.applescript [mono|stereo|toggle|status]

on run argv
	set modeArg to "toggle"
	if (count of argv) > 0 then
		set modeArg to item 1 of argv
	end if

	-- Read current state from defaults (1 = mono, 0 = stereo)
	set curVal to 0
	try
		set curValString to do shell script "defaults read com.apple.universalaccess stereoAsMono 2>/dev/null || echo 0"
		set curVal to curValString as integer
	on error
		set curVal to 0
	end try

	if modeArg is "status" or modeArg is "-s" or modeArg is "--status" then
		if curVal is 1 then
			return "mono"
		else
			return "stereo"
		end if
	end if

	set targetVal to 1
	if modeArg is "mono" or modeArg is "1" or modeArg is "true" or modeArg is "on" then
		set targetVal to 1
	else if modeArg is "stereo" or modeArg is "0" or modeArg is "false" or modeArg is "off" then
		set targetVal to 0
	else if modeArg is "toggle" then
		if curVal is 1 then
			set targetVal to 0
		else
			set targetVal to 1
		end if
	end if

	if curVal is equal to targetVal then
		if targetVal is 1 then
			return "Audio is already set to mono mode."
		else
			return "Audio is already set to stereo mode."
		end if
	end if

	-- Check if System Settings was running previously
	set wasRunning to false
	tell application "System Events"
		if exists (processes whose bundle identifier is "com.apple.systempreferences") then
			set wasRunning to true
		end if
	end tell

	-- Open Accessibility Settings Extension directly
	do shell script "open 'x-apple.systempreferences:com.apple.Accessibility-Settings.extension'"

	set success to false

	repeat with attempt from 1 to 30
		tell application "System Events"
			tell process "System Settings"
				try
					-- Case A: Check if we are already on the Audio subpane
					if exists checkbox "Play stereo audio as mono" of group 1 of scroll area 1 of group 1 of group 2 of splitter group 1 of group 1 of window 1 then
						set cb to checkbox "Play stereo audio as mono" of group 1 of scroll area 1 of group 1 of group 2 of splitter group 1 of group 1 of window 1
						set cbVal to value of cb
						if cbVal is not equal to targetVal then
							click cb
						end if
						set success to true
						exit repeat
					end if

					-- Case B: Find the Hearing section (first group in scroll area with 4 buttons) and click button 2 (Audio)
					set hearingGrp to missing value
					repeat with g in groups of scroll area 1 of group 1 of group 2 of splitter group 1 of group 1 of window 1
						if (count of buttons of g) is 4 then
							set hearingGrp to g
							exit repeat
						end if
					end repeat

					if hearingGrp is not missing value then
						click button 2 of hearingGrp
						delay 0.2
					end if
				on error
					delay 0.1
				end try
			end tell
		end tell
		delay 0.1
	end repeat

	-- Synchronize defaults setting
	if targetVal is 1 then
		do shell script "defaults write com.apple.universalaccess stereoAsMono -bool true"
	else
		do shell script "defaults write com.apple.universalaccess stereoAsMono -bool false"
	end if

	-- If System Settings was not open before, quit it cleanly
	if not wasRunning then
		tell application "System Settings" to quit
	end if

	if targetVal is 1 then
		return "Audio switched to mono mode."
	else
		return "Audio switched to stereo mode."
	end if
end run
