-- mail-flag-dispatch.applescript
--
-- Mail Rule entry point for the Mail flag → routing pipeline.
-- Mail calls this when a rule matches; we do ZERO real work here, just
-- serialize each message's identity to a .job file in the worker inbox.
-- The Python worker (mail-flag-worker) does extraction + routing.
--
-- Compile with:
--   osacompile -o ~/work/apple/bin/mail-flag-dispatch.scpt \
--              ~/work/apple/bin/mail-flag-dispatch.applescript

property INBOX_DIR : (POSIX path of (path to home folder)) & "work/comms/queue/mailflag-inbox/"

on jsonQuote(s)
	return do shell script "/usr/bin/python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' " & quoted form of (s as string)
end jsonQuote

on writeJobJSON(jobPath, payload)
	do shell script "/bin/mkdir -p " & quoted form of INBOX_DIR
	set tmpPath to jobPath & ".tmp"
	do shell script "/bin/cat > " & quoted form of tmpPath & " <<'__MAILFLAG_EOF__'
" & payload & "
__MAILFLAG_EOF__
/bin/mv " & quoted form of tmpPath & " " & quoted form of jobPath
end writeJobJSON

on slugify(s)
	return do shell script "/usr/bin/python3 -c 'import sys,re,hashlib; s=sys.argv[1]; out=re.sub(r\"[^A-Za-z0-9._-]\",\"_\",s)[:80]; print(out or hashlib.md5(s.encode()).hexdigest())' " & quoted form of (s as string)
end slugify

on handleMessage(m)
	using terms from application "Mail"
		try
			set fi to flag index of m
		on error
			set fi to -1
		end try
		if fi is -1 then return
		try
			set mid to message id of m
		on error
			set mid to "unknown-" & (do shell script "/usr/bin/uuidgen")
		end try
		try
			set subj to subject of m
		on error
			set subj to ""
		end try
		try
			set sndr to sender of m
		on error
			set sndr to ""
		end try
		try
			set mbox to name of (mailbox of m)
		on error
			set mbox to "INBOX"
		end try
		try
			set acct to name of (account of (mailbox of m))
		on error
			set acct to ""
		end try
		try
			set dt to date received of m
			set dtStr to (dt as string)
		on error
			set dtStr to ""
		end try

		set slug to my slugify(mid)
		set jobPath to INBOX_DIR & slug & ".job"

		set payload to "{" & ¬
			"\"message_id\":" & my jsonQuote(mid) & "," & ¬
			"\"flag_index\":" & (fi as string) & "," & ¬
			"\"subject\":" & my jsonQuote(subj) & "," & ¬
			"\"sender\":" & my jsonQuote(sndr) & "," & ¬
			"\"account\":" & my jsonQuote(acct) & "," & ¬
			"\"mailbox\":" & my jsonQuote(mbox) & "," & ¬
			"\"date_received\":" & my jsonQuote(dtStr) & "," & ¬
			"\"queued_at\":" & my jsonQuote((do shell script "/bin/date -u +%Y-%m-%dT%H:%M:%SZ")) & "," & ¬
			"\"status\":\"queued\"" & ¬
			"}"

		my writeJobJSON(jobPath, payload)
	end using terms from
end handleMessage

using terms from application "Mail"
	on perform mail action with messages theMessages for rule theRule
		repeat with m in theMessages
			my handleMessage(m)
		end repeat
	end perform mail action with messages
end using terms from

-- standalone test: select messages in Mail, then `osascript mail-flag-dispatch.scpt`
on run
	tell application "Mail"
		set sel to selection
	end tell
	repeat with m in sel
		my handleMessage(m)
	end repeat
end run
