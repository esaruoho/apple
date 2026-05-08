-- tabs-status.applescript — total open tabs across all Safari windows.

set repoRoot to (POSIX path of (path to home folder)) & "work/apple"
set cmd to repoRoot & "/safari-exporter/scripts/safari-exporter status"

try
	set output to do shell script "bash -lc " & quoted form of cmd
	display notification (output as text) with title "Safari status"
on error errMsg
	display notification ("Failed: " & errMsg) with title "Safari status"
end try
