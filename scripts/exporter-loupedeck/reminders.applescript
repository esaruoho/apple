-- reminders.applescript — per-list open reminder counts.

set repoRoot to (POSIX path of (path to home folder)) & "work/apple"
set cmd to repoRoot & "/reminders-exporter/scripts/reminders-exporter status"

try
	set output to do shell script "bash -lc " & quoted form of cmd
	display notification (output as text) with title "Reminders"
on error errMsg
	display notification ("Failed: " & errMsg) with title "Reminders"
end try
