-- Full battery status via IOKit (ioreg)
-- Tier 10: IOKit — reads hardware state directly
-- Usage: osascript scripts/workflows/hardware/hardware-battery-status.applescript

-- Concept: do shell script with ioreg
--   IOKit's ioreg command exposes raw hardware data from the kernel I/O registry.
--   AppleSmartBattery contains capacity, cycle count, temperature, and charging state.

set capacity to do shell script "ioreg -rc AppleSmartBattery | grep '\"CurrentCapacity\"' | awk '{print $NF}'"
set maxCap to do shell script "ioreg -rc AppleSmartBattery | grep '\"MaxCapacity\"' | awk '{print $NF}'"
set isCharging to do shell script "ioreg -rc AppleSmartBattery | grep '\"ExternalConnected\"' | awk '{print $NF}'"
set cycleCount to do shell script "ioreg -rc AppleSmartBattery | grep '\"CycleCount\"' | awk '{print $NF}'"
set tempRaw to do shell script "ioreg -rc AppleSmartBattery | grep '\"Temperature\"' | awk '{print $NF}'"

-- Temperature is in centidegrees Celsius
set tempC to (tempRaw as number) / 100
set pct to round ((capacity as number) / (maxCap as number) * 100)

set statusText to "Battery: " & pct & "%" & return
if isCharging is "Yes" then
	set statusText to statusText & "Charging: Yes (AC connected)" & return
else
	set statusText to statusText & "Charging: No (on battery)" & return
end if
set statusText to statusText & "Cycle Count: " & cycleCount & return
set statusText to statusText & "Temperature: " & tempC & "°C"

display dialog statusText with title "Battery Status" buttons {"OK"} default button "OK"
