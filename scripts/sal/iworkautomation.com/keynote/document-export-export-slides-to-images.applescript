property exportFormat : "PNG" -- "TIFF" "JPEG" "PNG"
property includeSkippedSlides : false
property compressionFactor : 1.0

-- THE DESTINATION FOLDER 
-- (see the "path" to command in the Standard Additions dictionary for other locations, such as documents folder, movies folder, desktop folder)
set the defaultDestinationFolder to (path to pictures folder)

tell application "Keynote"
	activate
	try
		if playing is true then tell the front document to stop
		
		if not (exists document 1) then error number -128
		
		-- DERIVE NAME FOR NEW FOLDER FROM NAME OF THE FRONT DOCUMENT
		set documentName to the name of the front document
		if documentName ends with ".key" then ¬
			set documentName to text 1 thru -5 of documentName
		
		-- CREATE AN EXPORT DESTINATION FOLDER
		-- IMPORTANT: IT’S ADVISED TO ALWAYS CREATE A NEW DESTINATION FOLDER, AS THE CONTENTS OF ANY TARGETED FOLDER WILL BE OVERWRITTEN
		tell application "Finder"
			set newFolderName to documentName
			set incrementIndex to 1
			repeat until not (exists folder newFolderName of defaultDestinationFolder)
				set newFolderName to documentName & "-" & (incrementIndex as string)
				set incrementIndex to incrementIndex + 1
			end repeat
			set the targetFolder to ¬
				make new folder at defaultDestinationFolder with properties ¬
					{name:newFolderName}
			set the targetFolderHFSPath to targetFolder as string
		end tell
		
		-- EXPORT THE DOCUMENT
		if exportFormat is "PNG" then
			-- EXPORT THE FRONT DOCUMENT TO PNG IMAGES
			export front document as slide images to file targetFolderHFSPath with properties ¬
				{image format:PNG, skipped slides:includeSkippedSlides}
		else if exportFormat is "JPEG" then
			-- EXPORT THE FRONT DOCUMENT TO JPEG IMAGES
			export front document as slide images to file targetFolderHFSPath with properties ¬
				{image format:JPEG, skipped slides:includeSkippedSlides ¬
					, compression factor:compressionFactor}
		else if exportFormat is "TIFF" then
			-- EXPORT THE FRONT DOCUMENT TO TIFF IMAGES
			export front document as slide images to file targetFolderHFSPath with properties ¬
				{image format:TIFF, skipped slides:includeSkippedSlides ¬
					, compression factor:compressionFactor}
		end if
	on error errorMessage number errorNumber
		display alert "EXPORT PROBLEM" message errorMessage
		error number -128
	end try
end tell

-- OPEN THE DESTINATION FOLDER
tell application "Finder"
	activate
	open the targetFolder
end tell
