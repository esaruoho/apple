-- latest-recording.applescript — open the newest Voice Memo.
-- Bind to a Loupedeck button.

set repoRoot to (POSIX path of (path to home folder)) & "work/apple"
set cmd to repoRoot & "/voice-memos-exporter/scripts/voice-memos-exporter open latest --quicktime"

try
	do shell script "bash -lc " & quoted form of cmd
	display notification "Opened latest voice memo in QuickTime" with title "Voice Memos"
on error errMsg
	display notification ("Failed: " & errMsg) with title "Voice Memos"
end try
