-- List audio input and output devices
-- Tier 10: IOKit — reads hardware state directly
-- Usage: osascript scripts/workflows/hardware/hardware-audio-devices.applescript

-- Concept: do shell script with system_profiler
--   SPAudioDataType reads audio device info from CoreAudio / IOKit.
--   Lists all input and output devices with sample rates and channel counts.

set audioInfo to do shell script "system_profiler SPAudioDataType 2>/dev/null | grep -E '^\\s{4}\\S|Manufacturer:|Output Channels:|Input Channels:|Sample Rate:' | head -40"

if audioInfo is "" then
	set audioInfo to "No audio device information available."
end if

display dialog audioInfo with title "Audio Devices" buttons {"OK"} default button "OK"
