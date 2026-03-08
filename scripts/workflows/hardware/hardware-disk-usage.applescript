-- Show disk usage for the startup volume
-- Tier 10: IOKit — reads hardware state directly
-- Usage: osascript scripts/workflows/hardware/hardware-disk-usage.applescript

-- Concept: do shell script with df
--   df reads filesystem stats from the kernel's VFS layer, backed by IOKit storage drivers.
--   The -h flag formats sizes in human-readable units (GB/TB).

set diskInfo to do shell script "df -h / | tail -1"

-- Parse the df output
set totalSize to do shell script "echo " & quoted form of diskInfo & " | awk '{print $2}'"
set usedSize to do shell script "echo " & quoted form of diskInfo & " | awk '{print $3}'"
set availSize to do shell script "echo " & quoted form of diskInfo & " | awk '{print $4}'"
set usedPct to do shell script "echo " & quoted form of diskInfo & " | awk '{print $5}'"

set statusText to "Startup Disk Usage" & return & return
set statusText to statusText & "Total:     " & totalSize & return
set statusText to statusText & "Used:      " & usedSize & " (" & usedPct & ")" & return
set statusText to statusText & "Available: " & availSize

display dialog statusText with title "Disk Usage" buttons {"OK"} default button "OK"
