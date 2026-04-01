-- The value of this property deternines whether the description for the new image should be its source URL or embedded description metadata (if any)
property replaceDescriptionWithURL : true

tell application "Keynote"
	activate
	if not (exists front document) then error number -128
	tell the front document
		-- check each slide for images whose description is a URL
		repeat with i from 1 to the count of slides
			tell slide i
				repeat with q from 1 to the count of images
					tell image q
						set currentDescription to the description
					end tell
					if currentDescription contains "://" then
						set newImageFile to my fileFromURL(currentDescription)
						if newImageFile is not false then
							set file name of image q to newImageFile
							if replaceDescriptionWithURL is true then
								set description of image q to currentDescription
							else -- attempt to retrieve embedded description
								set embeddedDescription to my extractkMDItemDescription(newImageFile)
								set description of image q to embeddedDescription
							end if
						end if
					end if
				end repeat
			end tell
		end repeat
	end tell
	start the front document from the first slide of the front document
end tell

on fileFromURL(currentDescription)
	try
		-- get the name of the file from the URL
		set the fileName to do shell script "basename " & currentDescription
		-- derive a path to the temp folder into which the image will be downloaded
		set the temporaryItemsFolder to ¬
			the POSIX path of (path to the temporary items folder)
		set the targetFile to (temporaryItemsFolder & fileName)
		-- download the image
		do shell script "curl" & space & currentDescription & space & "-o" & ¬
			space & quoted form of targetFile
		-- return an HFS alias file reference to the image file
		return targetFile as POSIX file as alias
	on error
		return false
	end try
end fileFromURL

on extractkMDItemDescription(thisImageFile)
	-- uses Spotlight to retrieve embedded description metadata (if any)
	try
		set thisImagePOSIXPath to the POSIX path of thisImageFile
		set the embeddedDescription to ¬
			do shell script "mdls -name kMDItemDescription " & ¬
				(quoted form of thisImagePOSIXPath)
		if embeddedDescription is "kMDItemDescription = (null)" then
			set embeddedDescription to ""
		else
			set the embeddedDescription to ¬
				(text from ((length of "kMDItemDescription = \"") + 1) to ¬
					-2 of embeddedDescription)
		end if
		return embeddedDescription
	on error
		return ""
	end try
end extractkMDItemDescription
