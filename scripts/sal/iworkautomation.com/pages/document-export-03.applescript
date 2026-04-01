property exportFileExtension : "epub"

-- THE DESTINATION FOLDER 
-- (see the "path" to command in the Standard Additions dictionary for other locations, such as movies folder, pictures folder, desktop folder)
set the defaultDestinationFolder to (path to documents folder)

tell application "Pages"
	activate
	try
		if not (exists document 1) then error number -128
		
		-- GET DOCUMENT NAME
		set documentName to the name of the front document
		if documentName ends with ".pages" then ¬
			set documentName to text 1 thru -7 of documentName
		
		-- PROMPT FOR TITLE
		repeat
			display dialog "Enter the title for the publication:" default answer documentName
			set thisTitle to the text returned of the result
			if thisTitle is not "" then exit repeat
		end repeat
		
		-- PROMPT FOR AUTHOR
		repeat
			display dialog "Enter the author for the publication:" default answer ""
			set thisAuthor to the text returned of the result
			if thisAuthor is not "" then exit repeat
		end repeat
		
		-- DETERMINE COVER
		display dialog "Should the created publication use this document’s first page as a cover?" buttons ¬
			{"Cancel", "No", "Yes"} default button 3
		set useFirstPageForCover to the button returned of the result as boolean
		
		-- DETERMINE FILENAME
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
			export front document to file targetFileHFSPath as epub ¬
				with properties {title:thisTitle, author:thisAuthor, cover:useFirstPageForCover}
		end timeout
		
	on error errorMessage number errorNumber
		if errorNumber is not -128 then
			display alert "EXPORT PROBLEM" message errorMessage
		end if
		error number -128
	end try
end tell

-- OPEN THE NEW EXPORT FILE
tell application "iBooks"
	activate
	open file targetFileHFSPath
end tell
