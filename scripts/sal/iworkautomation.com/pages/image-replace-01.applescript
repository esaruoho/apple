property thisTemplateName : "Thumbnail Poster"

tell application "Pages"
	activate
	try
		-- check for the required template
		set the templateNames to the name of every template
		if thisTemplateName is not in the templateNames then error number 1000
		
		-- prompt user to pick the source album
		set albumNames to my iPhotoAlbumNames()
		if albumNames is false then error number 1001
		set chosenAlbum to ¬
			(choose from list albumNames with prompt ¬
				"Pick the album containing images to import:")
		if chosenAlbum is false then error number -128
		
		-- get a list of file paths to the album images
		tell application "iPhoto"
			-- using previews reduces time required for script to complete
			-- use the "image path" property for higher resolution
			set the imagePaths to ¬
				the preview path of every photo of album (chosenAlbum as string)
			set albumImageCount to the count of the imagePaths
			if albumImageCount is 0 then error number 1002
		end tell
		
		-- make a new Pages document
		set thisDocument to make new document with properties ¬
			{document template:template thisTemplateName}
		tell thisDocument
			tell the current page
				set imageCount to the count of images
				repeat with i from 1 to the imageCount
					if i is greater than albumImageCount then error number 1003
					-- locate the image item by its description
					set thisImage to (the first image whose description is (i as string))
					-- convert the POSIX path to HFS file reference
					set thisImageFile to (item i of the imagePaths) as POSIX file
					-- replace the placeholder with the image
					set file name of thisImage to thisImageFile
				end repeat
			end tell
		end tell
		
		-- notify the user
		my displayThisNotification("New Pages Document", "Thumbnail document created.", "")
	on error errorMessage number errorNumber
		if errorNumber is 1000 then
			display alert "MISSING RESOURCE" message "This script requires the installation of a Pages template titled “" & thisTemplateName & ".”" & return & return & "The template can be downloaded from: iworkautomation.com" as critical buttons {"Download", "Stop"} default button 2
			if the button returned of the result is "Download" then
				open location "http://iworkautomation.com/pages/image-replace.html"
			end if
			error number -128
		else if errorNumber is 1001 then
			set errorNumber to "iPhoto Issue"
			set errorMessage to "There was a problem getting a list of albums from iPhoto."
		else if errorNumber is 1002 then
			set errorNumber to "iPhoto Issue"
			set errorMessage to "The chosen album contains no photos."
		else if errorNumber is 1003 then
			set errorNumber to "iPhoto Issue"
			set errorMessage to "There are more image placeholders than album images."
		end if
		if errorNumber is not -128 then
			display alert (errorNumber as string) message errorMessage
		end if
	end try
end tell

on displayThisNotification(thisTitle, thisNotification, thisSubtitle)
	tell current application
		display notification thisNotification with title thisTitle subtitle thisSubtitle
	end tell
end displayThisNotification

on iPhotoAlbumNames()
	try
		--get a list of iPhoto albums
		tell application "iPhoto"
			launch
			return (the name of every album)
		end tell
	on error
		return false
	end try
end iPhotoAlbumNames
