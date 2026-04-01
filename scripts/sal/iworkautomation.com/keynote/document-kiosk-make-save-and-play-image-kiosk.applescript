-- Create a new document and save it into the Documents folder
set the nameToUse to "Image Kiosk"
-- make sure the file name is not in use
set the destinationFolderHFSPath to ¬
	(path to the documents folder) as string
repeat with i from 0 to 100000
	if i is 0 then
		set incrementText to ""
	else
		set incrementText to "-" & (i as string)
	end if
	set thisFileName to nameToUse & incrementText & ".key"
	set thisFilePath to destinationFolderHFSPath & thisFileName
	tell application "Finder"
		if not (exists document file thisFilePath) then exit repeat
	end tell
end repeat

-- GET THE CURRENT SCREEN DIMENSIONS
tell application "Finder"
	copy the bounds of the window of the desktop to ¬
		{x, y, screenWidth, screenHeight}
end tell

-- CREATE A NEW PRESENTATION
tell application "Keynote"
	activate
	if playing is true then tell the front document to stop
	
	-- CREATE THE DOCUMENT
	set thisDocument to make new document with properties ¬
		{document theme:theme "Black", width:screenWidth, height:screenHeight}
	
	tell thisDocument
		set theseImages to {}
		repeat with i from 1 to 5
			if i is 1 then
				-- SET THE TITLE SLIDE
				set the base slide of the first slide to master slide "Title & Subtitle"
				tell slide i
					set the object text of the default title item to "Desktop Images"
					set the object text of the default body item to "Tap to View"
				end tell
			else
				-- MAKE NEW IMAGE SLIDE
				make new slide with properties {base slide:master slide "Blank"}
			end if
			
			-- GET THE RANDOM IMAGE
			repeat
				copy my getRandomDesktopPicture() to ¬
					{thisImageFileName, thisImageFile}
				if theseImages does not contain thisImageFileName then
					set the end of theseImages to thisImageFileName
					exit repeat
				end if
			end repeat
			-- trim the file extension (.jpg) from the file name
			set thisImageName to text 1 thru -5 of thisImageFileName
			
			-- ADD THE IMAGE FILE TO THE FIRST SLIDE
			tell slide i
				-- IMPORT THE DESKTOP IMAGE
				set thisImage to ¬
					make new image with properties {file:thisImageFile}
				tell thisImage
					set thisItemHeight to its height
					if thisItemHeight is not screenHeight then
						-- FILL IMAGE TO SLIDE HEIGHT AND CENTER
						set height of it to screenHeight
						set thisItemWidth to its width
						set the position of it to {((screenWidth - thisItemWidth) div 2), 0}
					end if
					if i is 1 then set opacity to 20
				end tell
				
				-- CREATE A TEXT OVERLAY DISPLAYING IMAGE NAME
				set thisTitleBox to ¬
					make new text item with properties {object text:thisImageName}
				tell thisTitleBox
					set font of object text of it to "Times New Roman Italic"
					set thisItemHeight to its height
					copy position of it to {horizontalPosition, verticalPositon}
					set position of it to {horizontalPosition, screenHeight - (thisItemHeight * 2)}
					if i is 1 then set opacity to 20
				end tell
				
				-- APPLY TRANSITION
				set the transition properties to ¬
					{transition effect:dissolve, transition duration:2.0, transition delay:0, automatic transition:false}
			end tell
		end repeat
		
		-- SET THE KIOSK PROPERTIES
		set auto play to true
		set auto loop to true
		set auto restart to true
		set maximum idle duration to 1 -- minute
		
		-- MOVE TO THE STARTING SLIDE BEFORE SAVING
		my moveToSlide(first slide of it)
	end tell
	
	-- SAVE AND CLOSE THE DOCUMENT
	save thisDocument in file thisFilePath
	close the front document saving no
	
end tell

-- LAUNCH THE KIOSK
tell application "Finder"
	open document file thisFilePath
end tell

on getRandomDesktopPicture()
	-- GET A RANDOM IMAGE FROM THE DESKTOP PICTURES FOLDER
	set desktopPicturesFolder to (path to desktop pictures folder)
	set the imageFileNames to every paragraph of ¬
		(do shell script "ls " & quoted form of POSIX path of desktopPicturesFolder)
	--> RETURNS: {"Abstract.jpg", "Antelope Canyon.jpg", "Bahamas Aerial.jpg", etc.}
	set thisImageFileName to some item of the imageFileNames
	--> RETURNS: "Mountain Range.jpg"
	set thisImageFile to ¬
		((desktopPicturesFolder as string) & thisImageFileName) as alias
	--> RETURNS: alias "Macintosh HD:Library:Desktop Pictures:Mountain Range.jpg"
	return {thisImageFileName, thisImageFile}
end getRandomDesktopPicture

on moveToSlide(thisSlide)
	tell application "Keynote"
		tell front document
			if thisSlide is last slide then
				start from slide before last slide
				tell application "Keynote"
					show slide switcher
					move slide switcher forward
					accept slide switcher
					stop front document
				end tell
			else
				set thisSlideNumber to slide number of thisSlide
				start from slide (thisSlideNumber + 1)
				tell application "Keynote"
					show slide switcher
					move slide switcher backward
					accept slide switcher
					stop front document
				end tell
			end if
		end tell
	end tell
end moveToSlide
