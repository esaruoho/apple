-- List connected USB devices
-- Tier 10: IOKit — reads hardware state directly
-- Usage: osascript scripts/workflows/hardware/hardware-usb-devices.applescript

-- Concept: do shell script with system_profiler
--   system_profiler reads IOKit data and formats it for humans.
--   SPUSBDataType enumerates all USB bus devices including hubs.

set usbInfo to do shell script "system_profiler SPUSBDataType -detailLevel mini 2>/dev/null | grep -E '^\\s{4}\\S|Product ID:|Vendor ID:|Speed:' | head -40"

if usbInfo is "" then
	set usbInfo to "No USB devices found."
end if

display dialog usbInfo with title "USB Devices" buttons {"OK"} default button "OK"
