-- today.applescript — show today's Calendar events as a notification.
-- Bind to a Loupedeck button. Calls calendar-exporter events.

set repoRoot to (POSIX path of (path to home folder)) & "work/apple"
set cmd to repoRoot & "/calendar-exporter/scripts/calendar-exporter events --since $(date +%Y-%m-%d) --until $(date -v+1d +%Y-%m-%d) --limit 8"

try
	set output to do shell script "bash -lc " & quoted form of cmd
on error errMsg
	set output to "calendar-exporter error: " & errMsg
end try

display notification (output as text) with title "Today's calendar"
