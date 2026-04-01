property exportFileExtension : "txt"--text

-- THE DESTINATION FOLDER 
-- (see the "path" to command in the Standard Additions dictionary for other locations, such as movies folder, pictures folder, desktop folder)
set the defaultDestinationFolder to (path to documents folder)

tell application "Pages"
	activate
	try
		if not (exists document 1) then error number -128
		
		-- DERIVE NAME AND FILE PATH FOR NEW EXPORT FILE
		set documentName to the name of the front document
		if documentName ends with ".pages" then ¬
			set documentName to text 1 thru -7 of documentName
		
		tell application "Finder"
			set newExportFileName to documentName & "." & exportFileExtension
			set incrementIndex to 1
			repeat until not (exists document file newExportFileName of defaultDestinationFolder)
				set newExportFileName to ¬
					documentName & "-" & (incrementIndex as string) & "." & exportFileExtension
				set incrementIndex to incrementIndex + 1
			end repeat
		end tell
		set the targetFileHFSPath to (defaultDestinationFolder as string) & newExportFileName
		
		-- EXPORT THE DOCUMENT
		with timeout of 1200 seconds
			export front document to file targetFileHFSPath as unformatted text
		end timeout
		
	on error errorMessage number errorNumber
		display alert "EXPORT PROBLEM" message errorMessage
		error number -128
	end try
end tell

-- SHOW THE NEW EXPORT FILE
tell application "Finder"
	activate
	reveal document file targetFileHFSPath
end tell
