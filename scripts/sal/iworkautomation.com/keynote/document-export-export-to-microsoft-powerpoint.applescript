-- Export the presentation as a MSPowerPoint 1997-2003 compatible file?
property attemptCompatibleExport : true

-- THE DESTINATION FOLDER 
-- (see the "path" to command in the Standard Additions dictionary for other locations, such as movies folder, pictures folder, desktop folder)
set the defaultDestinationFolder to (path to documents folder)

tell application "Keynote"
	activate
	try
		if playing is true then tell the front document to stop
		
		if not (exists document 1) then error number -128
		
		tell front document
			set documentName to its name
			if documentName ends with ".key" then ¬
				set documentName to text 1 thru -5 of documentName
			set movieCount to the count of every movie of every slide
			set audioClipCount to the count of every audio clip of every slide
		end tell
		
		-- Check for media. Presentations containing media must be saved as PPTX
		if movieCount is 0 and audioClipCount is 0 and attemptCompatibleExport is true then
			set MicrosoftPowerPointFileExtension to "ppt"
		else
			set MicrosoftPowerPointFileExtension to "pptx"
		end if
		
		tell application "Finder"
			set newExportItemName to documentName & "." & MicrosoftPowerPointFileExtension
			set incrementIndex to 1
			repeat until not (exists document file newExportItemName of defaultDestinationFolder)
				set newExportItemName to ¬
					documentName & "-" & (incrementIndex as string) & "." & MicrosoftPowerPointFileExtension
				set incrementIndex to incrementIndex + 1
			end repeat
		end tell
		set the targetFileHFSPath to (defaultDestinationFolder as string) & newExportItemName
		
		-- EXPORT THE DOCUMENT
		with timeout of 1200 seconds
			export front document to file targetFileHFSPath as Microsoft PowerPoint
		end timeout
		
		set exportedItemPath to targetFileHFSPath
		
	on error errorMessage number errorNumber
		display alert "EXPORT PROBLEM" message errorMessage
		error number -128
	end try
end tell

-- SHOW THE NEW EXPORTED FILE
tell application "Finder"
	activate
	set exportedFile to (document file exportedItemPath)
	set extension hidden of exportedFile to false
	reveal exportedFile
end tell
