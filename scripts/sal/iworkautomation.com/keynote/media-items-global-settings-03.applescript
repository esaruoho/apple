tell application "Keynote"
	activate
	if not (exists document 1) then error number -128
	tell the front document
		repeat
			display dialog "Enter a volume (from 0 to 100) to apply to all movies in this document:" default answer "100"
			try
				set thisValue to the text returned of the result as integer
				if thisValue is greater than or equal to 0 and ¬
					thisValue is less than or equal to 100 then exit repeat
			end try
		end repeat
		set movie volume of every movie of every slide to thisValue
	end tell
end tell
