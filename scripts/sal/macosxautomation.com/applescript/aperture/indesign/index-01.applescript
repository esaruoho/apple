-- SUB-ROUTINE FOR EXTRACTING APERTURE ID FROM FINGERPRINTED PREVIEW FILES
on get_ID(this_imagefile)
	-- the variable this_imagefile can be either an HFS path ("Macintosh HD:Users:Pat:Pictures:preview-02.jpg")
	-- or a file reference in alias format (alias "Macintosh HD:Users:Pat:Pictures:preview-02.jpg")
	set this_imagefile to this_imagefile as alias
	set this_imagepath to the POSIX path of this_imagefile
	-- if the preview is located within an Aperture library, you must force Spotlight to index its metadata
	if this_imagepath contains ".aplibrary" then
		tell application "System Events"
			set this_folder to the POSIX path of the container of this_imagefile
		end tell
		do shell script "mdimport " & (the quoted form of this_folder)
	end if
	set the scan_result to (do shell script "mdls -name kMDItemInstructions " & (quoted form of this_imagepath))
	if the scan_result is not "" then
		set the scan_result to text from ((offset of "=" in scan_result) + 3) to -2 of the scan_result
		if scan_result is "null" then set scan_result to missing value
	else
		set scan_result to missing value
	end if
	return scan_result
end get_ID
