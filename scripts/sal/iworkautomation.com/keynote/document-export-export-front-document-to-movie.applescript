property movieFileExtension : "m4v"

-- THE DESTINATION FOLDER 
-- (see the "path" to command in the Standard Additions dictionary for other locations, such as documents folder, pictures folder, desktop folder)
set the defaultDestinationFolder to (path to movies folder)

tell application "Keynote"
	activate
	try
		if playing is true then tell the front document to stop
		
		if not (exists document 1) then error number -128
		
		-- DERIVE NAME AND FILE PATH FOR NEW MOVIE FILE
		set documentName to the name of the front document
		if documentName ends with ".key" then ¬
			set documentName to text 1 thru -5 of documentName
		
		tell application "Finder"
			set newMovieFileName to documentName & "." & movieFileExtension
			set incrementIndex to 1
			repeat until not (exists document file newMovieFileName of defaultDestinationFolder)
				set newMovieFileName to ¬
					documentName & "-" & (incrementIndex as string) & "." & movieFileExtension
				set incrementIndex to incrementIndex + 1
			end repeat
		end tell
		set the targetFileHFSPath to (defaultDestinationFolder as string) & newMovieFileName
		
		-- EXPORT THE DOCUMENT
		with timeout of 1200 seconds
			export front document to file targetFileHFSPath ¬
				as QuickTime movie with properties {movie format:large}
		end timeout
		
	on error errorMessage number errorNumber
		display alert "EXPORT PROBLEM" message errorMessage
		error number -128
	end try
end tell

-- SHOW THE NEW MOVIE FILE
tell application "Finder"
	activate
	reveal document file targetFileHFSPath
end tell
