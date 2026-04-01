use AppleScript version "2.4" -- Yosemite (10.10) or later
use scripting additions

tell application "Pixelmator Pro 3"
	activate
	try
		if not (exists document 1) then error number -128
		tell front document
			tell current layer of it
				set height to (height div 2)
				set width to (width div 2)
			end tell
		end tell
	on error errorMessage number errorNumber
		if errorNumber is not -128 then
			display alert (errorNumber as string) message errorMessage
		end if
	end try
end tell
