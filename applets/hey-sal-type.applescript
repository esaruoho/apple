-- Hey Sal (Type) — Spotlight-launchable typed entry to the same router.
-- Pops a text dialog, sends what you typed to ~/work/apple/bin/hey-sal,
-- and (via that router) dispatches to Paketti / Renoise / Sal verbs.

on run
	set heySalLog to (POSIX path of (path to home folder)) & "Library/Logs/HeySal.log"
	try
		set userText to text returned of (display dialog "Hey Sal:" default answer "" with title "Hey Sal" buttons {"Cancel", "Run"} default button "Run" with icon note)
	on error number -128
		return
	end try
	set userText to do shell script "/bin/echo " & quoted form of userText & " | /usr/bin/sed 's/^[[:space:]]*//;s/[[:space:]]*$//'"
	if userText is "" then return
	-- Log it the same way the voice Shortcut does.
	do shell script "/bin/echo " & quoted form of ("--- " & ((current date) as text) & " (typed) ---" & linefeed & "input: " & userText) & " >> " & quoted form of heySalLog
	-- Dispatch via the Hey Sal router (which knows the 337 Paketti verbs).
	set heySalBin to (POSIX path of (path to home folder)) & "work/apple/bin/hey-sal"
	set runResult to do shell script quoted form of heySalBin & " " & quoted form of userText & " 2>&1"
	-- Show the result briefly so user sees what happened.
	do shell script "/bin/echo " & quoted form of ("result:" & linefeed & runResult) & " >> " & quoted form of heySalLog
end run
