property templateName : "Type Poster Big"
property templateWidth : 792
property templateHeight : 1224
property defaultMargin : 36
-- for smaller thumbnails, adjust columnCount to higher number
property columnCount : 6

-- derive image dimensions, row count, and image count
set imageDimension to (templateWidth - (defaultMargin * 2)) div columnCount
set rowCount to (templateHeight - (defaultMargin * 2)) div imageDimension
set imageCount to rowCount * columnCount

try
	--get a list of iPhoto albums
	tell application "iPhoto"
		launch
		set albumNames to the name of every album
	end tell
	
	tell application "Pages"
		activate
		-- prompt user to pick the source album
		set chosenAlbum to ¬
			(choose from list albumNames with prompt ¬
				"Pick the album containing " & imageCount & " images to import:")
		if chosenAlbum is false then error number -128
		-- get a list of file paths to the album images
		tell application "iPhoto"
			-- using previews reduces time required for script to complete
			-- use the "image path" property for higher resolution
			set the imagePaths to ¬
				the preview path of every photo of album (chosenAlbum as string)
			set albumImageCount to the count of the imagePaths
		end tell
		-- create a temporary folder
		tell current application
			set the temporaryItemsFolderPath to ¬
				the POSIX path of (path to pictures folder)
			set thisUUID to (do shell script "uuidgen")
			set temporaryFolderPath to (temporaryItemsFolderPath & thisUUID)
			do shell script "mkdir" & space & quoted form of temporaryFolderPath
		end tell
		-- make a new Pages document
		set thisDocument to make new document with properties ¬
			{document template:template templateName}
		
		tell thisDocument
			-- clear the document of existing items
			set locked of every iWork item to false
			delete every iWork item
			-- create the grid of square image thumbnails
			set rowOffset to defaultMargin
			set columnOffset to defaultMargin
			set imageCounter to 1
			repeat with q from 1 to the rowCount
				set rowOffset to defaultMargin
				repeat with i from 1 to the columnCount
					-- get the source image path
					set thisImagePOSIXPath to (item imageCounter of imagePaths)
					-- duplicate the source image to the temp folder
					tell current application
						set imageFileName to ¬
							(do shell script "basename" & space & ¬
								quoted form of thisImagePOSIXPath)
						do shell script "cp" & space & quoted form of thisImagePOSIXPath & ¬
							space & quoted form of temporaryFolderPath
						set duplicateImageFile to ¬
							(temporaryFolderPath & "/" & imageFileName)
					end tell
					-- pad the image to a square
					set thisImageFile to my padToSquare(duplicateImageFile, true)
					-- add the padded image to the layout
					tell current page
						make new image with properties ¬
							{height:imageDimension ¬
								, width:imageDimension ¬
								, position:{rowOffset, columnOffset} ¬
								, file:thisImageFile}
					end tell
					-- delete the padded source image file
					tell current application
						do shell script "rm" & space & quoted form of thisImageFile
					end tell
					-- increment the grid counters
					set rowOffset to rowOffset + imageDimension
					if imageCounter is albumImageCount then
						set imageCounter to 1
					else
						set imageCounter to imageCounter + 1
					end if
				end repeat
				set columnOffset to columnOffset + imageDimension
			end repeat
		end tell
	end tell
	-- delete the temp folder
	tell current application
		do shell script "rmdir" & space & quoted form of temporaryFolderPath
	end tell
	-- notify the user
	displayThisNotification("New Pages Document", "Thumbnail document created.", "")
on error errorMessage number errorNumber
	if errorNumber is not -128 then
		tell application "Pages"
			activate
			display alert (errorNumber as string) message errorMessage
		end tell
	end if
end try

on displayThisNotification(thisTitle, thisNotification, thisSubtitle)
	tell current application
		display notification thisNotification with title thisTitle subtitle thisSubtitle
	end tell
end displayThisNotification

on padToSquare(thisImageFile, applyScale)
	set scaleDimension to 1024
	try
		tell application "Image Events"
			-- start the Image Events application
			launch
			-- open the image file
			set thisImage to open thisImageFile
			-- get dimensions of the image
			copy dimensions of thisImage to {imageWidth, imageHeight}
			-- calculate pad dimensions
			if imageWidth is greater than imageHeight then
				set imageDimension to imageWidth
			else
				set imageDimension to imageHeight
			end if
			set padDimensions to {imageDimension, imageDimension}
			-- perform padding
			pad thisImage to dimensions padDimensions ¬
				with pad color {65535, 65535, 65535}
			if applyScale is true then
				if imageDimension is greater than scaleDimension then
					-- perform scaling
					scale thisImage to size scaleDimension
				end if
			end if
			-- save the changes
			save thisImage with icon
			-- purge the open image data
			close thisImage
		end tell
		return thisImageFile
	on error error_message
		display dialog error_message
	end try
end padToSquare
