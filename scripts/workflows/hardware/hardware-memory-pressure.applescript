-- Show memory pressure and usage statistics
-- Tier 10: IOKit — reads hardware state directly
-- Usage: osascript scripts/workflows/hardware/hardware-memory-pressure.applescript

-- Concept: do shell script with vm_stat and sysctl
--   vm_stat reads Mach virtual memory statistics from the kernel.
--   Memory page size is typically 16384 bytes on Apple Silicon, 4096 on Intel.

set totalMem to do shell script "sysctl -n hw.memsize"
set totalGB to round ((totalMem as number) / 1.073741824E+9 * 10) / 10

-- Get page size and vm_stat data
set pageSize to do shell script "sysctl -n hw.pagesize"
set pageSizeNum to pageSize as number

set freePages to do shell script "vm_stat | grep 'Pages free' | awk '{print $NF}' | tr -d '.'"
set activePages to do shell script "vm_stat | grep 'Pages active' | awk '{print $NF}' | tr -d '.'"
set wiredPages to do shell script "vm_stat | grep 'Pages wired' | awk '{print $NF}' | tr -d '.'"
set compressedPages to do shell script "vm_stat | grep 'Pages occupied by compressor' | awk '{print $NF}' | tr -d '.'"

-- Convert to GB
set freeGB to round ((freePages as number) * pageSizeNum / 1.073741824E+9 * 100) / 100
set activeGB to round ((activePages as number) * pageSizeNum / 1.073741824E+9 * 100) / 100
set wiredGB to round ((wiredPages as number) * pageSizeNum / 1.073741824E+9 * 100) / 100
set compressedGB to round ((compressedPages as number) * pageSizeNum / 1.073741824E+9 * 100) / 100

set statusText to "Total Memory: " & totalGB & " GB" & return & return
set statusText to statusText & "Free:       " & freeGB & " GB" & return
set statusText to statusText & "Active:     " & activeGB & " GB" & return
set statusText to statusText & "Wired:      " & wiredGB & " GB" & return
set statusText to statusText & "Compressed: " & compressedGB & " GB"

display dialog statusText with title "Memory Pressure" buttons {"OK"} default button "OK"
