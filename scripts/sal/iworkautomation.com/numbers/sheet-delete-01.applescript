tell application "Numbers"
	activate
	tell the front document
		repeat with i from (count of sheets) to 1 by -1
			if the (count of tables of sheet i) is 0 then
				delete sheet i
			end if
		end repeat
	end tell
end tell
