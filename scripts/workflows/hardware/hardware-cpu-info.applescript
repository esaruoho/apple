-- Show CPU model, core count, and current load
-- Tier 10: IOKit — reads hardware state directly
-- Usage: osascript scripts/workflows/hardware/hardware-cpu-info.applescript

-- Concept: do shell script with sysctl
--   sysctl reads kernel state including CPU topology from IOKit's platform expert.
--   On Apple Silicon, machdep.cpu.brand_string may be empty; use hw.model instead.

try
	set cpuBrand to do shell script "sysctl -n machdep.cpu.brand_string 2>/dev/null"
on error
	set cpuBrand to ""
end try

if cpuBrand is "" then
	-- Apple Silicon: use machine model
	set cpuBrand to do shell script "sysctl -n hw.model 2>/dev/null || echo 'Unknown'"
end if

set totalCores to do shell script "sysctl -n hw.ncpu"
set physCores to do shell script "sysctl -n hw.physicalcpu"
set perfCores to do shell script "sysctl -n hw.perflevel0.physicalcpu 2>/dev/null || echo 'N/A'"
set effCores to do shell script "sysctl -n hw.perflevel1.physicalcpu 2>/dev/null || echo 'N/A'"

-- Current load average
set loadAvg to do shell script "sysctl -n vm.loadavg | awk '{print $2, $3, $4}'"

set statusText to "CPU: " & cpuBrand & return & return
set statusText to statusText & "Physical Cores: " & physCores & return
set statusText to statusText & "Logical Cores:  " & totalCores & return
if perfCores is not "N/A" then
	set statusText to statusText & "Performance:    " & perfCores & return
	set statusText to statusText & "Efficiency:     " & effCores & return
end if
set statusText to statusText & return & "Load Average: " & loadAvg

display dialog statusText with title "CPU Info" buttons {"OK"} default button "OK"
