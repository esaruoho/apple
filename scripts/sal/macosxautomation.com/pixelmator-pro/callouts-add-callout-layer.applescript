use AppleScript version "2.4" -- Yosemite (10.10) or later
use scripting additions

property folderName : "Callouts"
property sourceDirectory : path to "sdat" -- Shared folder
(* path to pictures folder *)
(* path to documents folder *)
(* path to public folder *)

set imagesFolderHFSPath to (sourceDirectory as string) & folderName

tell application "Pixelmator Pro 3"
	activate
	try
		if not (exists document 1) then error number -128
		set imagesFolder to imagesFolderHFSPath as alias
		set chosenImageFile to choose file of type "public.image" with prompt "Select image to import:" default location imagesFolder
		set imageFileInfo to the info for chosenImageFile
		set nameExtenstion to the name extension of the imageFileInfo
		set chosenImageFileName to the displayed name of the imageFileInfo
		set layerName to text 1 thru -((length of nameExtenstion) + 2) of chosenImageFileName
		tell front document
			make new image layer with properties {file:chosenImageFile, preserve transparency:true, constrain proportions:false, name:layerName}
		end tell
	on error errorMessage number errorNumber
		if errorNumber is not -128 then
			display alert (errorNumber as string) message errorMessage
		end if
	end try
end tell
