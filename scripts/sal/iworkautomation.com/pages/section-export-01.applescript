global globalErrorMessage
-- reset the global error variable
set globalErrorMessage to missing value
tell application "Pages"
	activate
	try
		-- check for open document
		if not (exists document 1) then error number 1000
		tell front document
			-- check for document body
			if document body is false then error number 1001
			-- prompt the user for a destination folder
			set destinationFolder to ¬
				(choose folder with prompt ¬
					"Choose the folder in which to place a folder containing the output files:")
			-- prompt the user for a basename for the files:
			repeat
				display dialog "Enter the base name to use for the exported files:" default answer ""
				set the exportBasename to the text returned of the result
				if the exportBasename is not "" then exit repeat
			end repeat
			-- export the sections as files
			repeat with i from 1 to the count of sections
				set thisText to the body text of section i
				set thisFileName to exportBasename & (i as string)
				set targetFileHFSPath to (destinationFolder as string) & thisFileName & ".txt"
				set writeResult to my writeToFile(thisText, targetFileHFSPath, false)
				if writeResult is false then error number 1002
			end repeat
		end tell
		-- notify the user
		display notification "Export completed." with title "Pages AppleScript"
	on error errorMessage number errorNumber
		if errorNumber is 1000 then
			set alertString to "MISSING RESOURCE"
			set errorMessage to "Please create or open a document before running this script."
		else if errorNumber is 1001 then
			set alertString to "INCOMPATIBLE DOCUMENT"
			set errorMessage to "This document does not have a document body."
		else if errorNumber is 1002 then
			set alertString to "EXPORT PROBLEM"
			set errorMessage to globalErrorMessage
		else
			set alertString to "EXECUTION ERROR"
		end if
		if errorNumber is not -128 then
			display alert alertString message errorMessage buttons {"Cancel"}
		end if
		error number -128
	end try
end tell

on writeToFile(thisData, targetFileHFSPath, shouldAppendData)
	try
		set the targetFileHFSPath to the targetFileHFSPath as string
		set the open_targetFileHFSPath to ¬
			open for access file targetFileHFSPath with write permission
		if shouldAppendData is false then set eof of the open_targetFileHFSPath to 0
		write thisData to the open_targetFileHFSPath starting at eof
		close access the open_targetFileHFSPath
		return true
	on error errorMessage
		try
			close access file targetFileHFSPath
		end try
		-- set the global error message to the error
		set globalErrorMessage to errorMessage
		return false
	end try
end writeToFile
