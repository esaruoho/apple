property defaultImageWidth : 792 -- in points
property defaultTypeSize : 36

tell application "Numbers"
	activate
	
	-- CREATE THE DOCUMENT
	set thisDocument to make new document with properties ¬
		{document template:template "Blank"}
	
	tell thisDocument
		
		-- GET THE RANDOM IMAGE
		copy my getRandomDesktopPicture() to {thisImageFileName, thisImageFile}
		-- trim the file extension (.jpg) from the file name
		set thisImageName to text 1 thru -5 of thisImageFileName
		
		-- ADD THE IMAGE FILE TO THE FIRST SLIDE
		tell the active sheet
			-- CLEAR THE CANVAS
			delete every table
			
			-- IMPORT THE DESKTOP IMAGE
			set thisImage to ¬
				make new image with properties {file:thisImageFile}
			tell thisImage
				set width to defaultImageWidth
				set position to {0, 0}
				set opacity to 100
				set imageWidth to its width
				set imageHeight to its height
				copy position of it to {imageHPosition, imageVPositon}
			end tell
			
			-- CREATE A TEXT OVERLAY DISPLAYING IMAGE NAME
			set thisTitleBox to ¬
				make new text item with properties {object text:thisImageName}
			tell thisTitleBox
				tell its object text
					set font to "Times New Roman Italic"
					set size to defaultTypeSize
					set color of it to {65535, 65535, 65535}
				end tell
				set textItemHeight to its height
				set textItemWidth to its width
				
				copy position of it to {textHPosition, textVPosition}
				set newHPosition to imageHPosition + ((imageWidth div 2) - (textItemWidth div 2))
				set newVPosition to imageVPositon + 24
				set position of it to {newHPosition, newVPosition}
			end tell
			
			-- CREATE AN OVERLAY TABLE
			set thisTable to make new table
			tell thisTable
				set the background color of cell range to {65535, 65535, 65535}
				set tableWidth to its width
				set tableHeight to its height
				set newHPosition to imageHPosition + ((imageWidth div 2) - (tableWidth div 2))
				set newVPosition to imageVPositon + (imageHeight - tableHeight - 36)
				set position of it to {newHPosition, newVPosition}
			end tell
		end tell
	end tell
end tell

on getRandomDesktopPicture()
	-- GET A RANDOM IMAGE FROM THE DESKTOP PICTURES FOLDER
	set desktopPicturesFolder to (path to desktop pictures folder)
	set the imageFileNames to every paragraph of ¬
		(do shell script "ls " & quoted form of POSIX path of desktopPicturesFolder)
	--> RETURNS: {"Abstract.jpg", "Antelope Canyon.jpg", "Bahamas Aerial.jpg", etc.}
	set thisImageFileName to some item of the imageFileNames
	--> RETURNS: "Mountain Range.jpg"
	set thisImageFile to ((desktopPicturesFolder as string) & thisImageFileName) as alias
	--> RETURNS: alias "Macintosh HD:Library:Desktop Pictures:Mountain Range.jpg"
	return {thisImageFileName, thisImageFile}
end getRandomDesktopPicture
