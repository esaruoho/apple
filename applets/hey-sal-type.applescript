-- Hey Sal (Type) — Spotlight-launchable typed entry to the same router.
-- Pops a text dialog, sends what you typed to ~/work/apple/bin/hey-sal,
-- and shows the result in a clean dialog (not macOS's red error dialog,
-- regardless of hey-sal's exit code).

on run
	set heySalLog to (POSIX path of (path to home folder)) & "Library/Logs/HeySal.log"
	set heySalBin to (POSIX path of (path to home folder)) & "work/apple/bin/hey-sal"
	try
		set userText to text returned of (display dialog "Hey Sal:" default answer "" with title "Hey Sal" buttons {"Cancel", "Run"} default button "Run" with icon note)
	on error number -128
		return
	end try
	set userText to do shell script "/bin/echo " & quoted form of userText & " | /usr/bin/sed 's/^[[:space:]]*//;s/[[:space:]]*$//'"
	if userText is "" then return
	do shell script "/bin/echo " & quoted form of ("--- " & ((current date) as text) & " (typed) ---" & linefeed & "input: " & userText) & " >> " & quoted form of heySalLog
	-- Run hey-sal; capture stdout AND stderr regardless of exit code so
	-- non-zero exits show as a calm dialog, not a yellow-triangle error.
	set runResult to ""
	set runRC to 0
	try
		set runResult to do shell script quoted form of heySalBin & " " & quoted form of userText & " 2>&1"
	on error errMsg number errNum
		set runResult to errMsg
		set runRC to errNum
	end try
	do shell script "/bin/echo " & quoted form of ("rc: " & runRC & linefeed & "result:" & linefeed & runResult) & " >> " & quoted form of heySalLog
	if runResult is "" then set runResult to "(no output)"
	if (length of runResult) > 2000 then
		set runResult to (text 1 thru 2000 of runResult) & "
…(truncated)"
	end if
	display dialog runResult with title "Hey Sal" buttons {"OK"} default button "OK" with icon note
end run
