property exportFileExtension : "csv"

-- THE DESTINATION FOLDER 
-- (see the "path" to command in the Standard Additions dictionary for other locations, such as movies folder, pictures folder, desktop folder)
set the defaultDestinationFolder to (path to documents folder)

tell application "Numbers"
	activate
	try
		if not (exists document 1) then error number -128
		
		tell front document
			set documentName to its name
			if documentName ends with ".numbers" then ¬
				set documentName to text 1 thru -9 of documentName
			set tableCount to the count of every table of every sheet
		end tell
		
		-- A DOCUMENT WITH ONE TABLE WILL EXPORT TO A FILE 
		if tableCount is 0 then
			tell application "Finder"
				set newExportItemName to documentName & "." & exportFileExtension
				set incrementIndex to 1
				repeat until not (exists document file newExportItemName of defaultDestinationFolder)
					set newExportItemName to ¬
						documentName & "-" & (incrementIndex as string) & "." & exportFileExtension
					set incrementIndex to incrementIndex + 1
				end repeat
			end tell
			set the targetFileHFSPath to ¬
				(defaultDestinationFolder as string) & newExportItemName
			
			-- EXPORT THE DOCUMENT
			with timeout of 1200 seconds
				export front document to file targetFileHFSPath as CSV
			end timeout
			
			set exportedItemPath to targetFileHFSPath
		else
			-- A DOCUMENT CONTAINING MULTIPLE TABLES WILL EXPORT TO A FOLDER
			tell application "Finder"
				set newFolderName to documentName
				set incrementIndex to 1
				repeat until not (exists folder newFolderName of defaultDestinationFolder)
					set newFolderName to documentName & "-" & (incrementIndex as string)
					set incrementIndex to incrementIndex + 1
				end repeat
				set targetHFSPath to (defaultDestinationFolder as string) & ¬
					newFolderName & "." & exportFileExtension
			end tell
			
			-- EXPORT THE DOCUMENT
			with timeout of 1200 seconds
				export front document as CSV to file targetHFSPath
			end timeout
			
			set exportedItemPath to ¬
				(defaultDestinationFolder as string) & newFolderName & ":"
		end if
		
	on error errorMessage number errorNumber
		if errorNumber is not -128 then
			display alert "EXPORT PROBLEM" message errorMessage
		end if
		error number -128
	end try
end tell

-- SHOW THE NEW EXPORTED ITEM
tell application "Finder"
	activate
	reveal item exportedItemPath
end tell
