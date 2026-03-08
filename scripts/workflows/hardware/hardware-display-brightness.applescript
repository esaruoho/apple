-- Display current screen brightness level
-- Tier 10: IOKit — reads hardware state directly
-- Usage: osascript scripts/workflows/hardware/hardware-display-brightness.applescript

-- Concept: do shell script with ioreg
--   IOKit exposes display brightness through the IODisplayConnect registry entry.
--   The brightness value is a float between 0.0 and 1.0.

try
	set brightnessRaw to do shell script "ioreg -rc AppleBacklightDisplay | grep '\"brightness\"' | head -1 | awk -F'= ' '{print $2}' | awk -F'}' '{print $1}'"
	if brightnessRaw is "" then
		-- Fallback: try AppleDisplay
		set brightnessRaw to do shell script "ioreg -rc AppleDisplay | grep '\"brightness\"' | head -1 | awk -F'\"brightness\"=' '{print $2}' | awk '{print $1}'"
	end if
on error
	set brightnessRaw to ""
end try

if brightnessRaw is not "" then
	try
		set brightnessNum to (brightnessRaw as number)
		-- If value is large, it may be in a different scale
		if brightnessNum > 1 then
			set pct to round (brightnessNum / 10.24)
		else
			set pct to round (brightnessNum * 100)
		end if
		display dialog "Display Brightness: " & pct & "%" with title "Display Brightness" buttons {"OK"} default button "OK"
	on error
		display dialog "Brightness raw value: " & brightnessRaw with title "Display Brightness" buttons {"OK"} default button "OK"
	end try
else
	-- Fallback: use pmset to check display state
	set pmsetInfo to do shell script "pmset -g | grep displaysleep || echo 'Unable to read brightness from IOKit'"
	display dialog pmsetInfo with title "Display Brightness" buttons {"OK"} default button "OK"
end if
