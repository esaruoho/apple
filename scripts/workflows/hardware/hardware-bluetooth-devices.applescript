-- List Bluetooth devices and connection status
-- Tier 10: IOKit — reads hardware state directly
-- Usage: osascript scripts/workflows/hardware/hardware-bluetooth-devices.applescript

-- Concept: do shell script with system_profiler
--   SPBluetoothDataType reads the Bluetooth controller state from IOKit.
--   Shows paired devices, connection status, and hardware addresses.

set btInfo to do shell script "system_profiler SPBluetoothDataType 2>/dev/null | grep -E '^\\s{4}\\S|Address:|Connected:|Battery' | head -40"

if btInfo is "" then
	set btInfo to "No Bluetooth information available."
end if

display dialog btInfo with title "Bluetooth Devices" buttons {"OK"} default button "OK"
