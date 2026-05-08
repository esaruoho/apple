-- hey-sal.applescript — trigger a Hey Sal utterance.
-- Bind to a Loupedeck button. Prompts for text (use macOS Dictation).

set repoRoot to (POSIX path of (path to home folder)) & "work/apple"

set userInput to text returned of (display dialog "Hey Sal —" default answer "" buttons {"Cancel", "Ask"} default button "Ask")
if userInput is "" then return

set cmd to repoRoot & "/bin/hey-sal " & quoted form of userInput & " --speak"

try
	set output to do shell script "bash -lc " & quoted form of cmd
	display notification (text 1 thru 200 of (output as text)) with title "Hey Sal"
on error errMsg
	display notification ("Hey Sal error: " & errMsg) with title "Hey Sal"
end try
