-- USER ADJUSTABLE VALUES
property backgroundImageOpacity : 20
property foregroundImageReflectionValue : 85
property textLabelTypeface : "Zapfino"
property textLabelSize : 36
property textLabelOffsetPercentage : 85

-- GET THE CURRENT SCREEN DIMENSIONS
tell application "Finder"
	copy the bounds of the window of the desktop to {x, y, screenWidth, screenHeight}
end tell

-- CREATE A NEW PRESENTATION
tell application "Keynote"
	activate
	if playing is true then tell the front document to stop
	
	-- CREATE THE DOCUMENT
	set thisDocument to make new document with properties ¬
		{document theme:theme "Black", width:screenWidth, height:screenHeight}
	
	tell thisDocument
		set the base slide of the first slide to master slide "Blank"
		
		-- GET THE RANDOM IMAGE
		copy my getRandomDesktopPicture() to {thisImageFileName, thisImageFile}
		-- trim the file extension (.jpg) from the file name
		set thisImageName to text 1 thru -5 of thisImageFileName
		
		-- ADD THE IMAGE FILE TO THE FIRST SLIDE
		tell the first slide
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
				-- fade the background image
				set its opacity to backgroundImageOpacity
				-- add a VoiceOver description
				set its description to ¬
					"A faded full-screen version of the image named “" & ¬
					thisImageName & ".”"
			end tell
			
			-- IMPORT THE SAME DESKTOP IMAGE
			set thisImage to ¬
				make new image with properties {file:thisImageFile}
			-- ADJUST THE IMAGE TO REDUCED SIZE IN UPPER CENTER
			set smallImageWidth to (screenWidth div 2)
			tell thisImage
				set width to smallImageWidth
				set newHeight to its height
				set the position of thisImage to ¬
					{(screenWidth - smallImageWidth) div 2, screenHeight div 4}
				-- set image properties
				set reflection showing to true
				set reflection value to foregroundImageReflectionValue
				copy position to {smallImageHorizOffset, smallImageVertOffset}
				-- add a VoiceOver description
				set its description to "An image named “" & thisImageName & ".”"
			end tell
			
			-- CREATE A TEXT OVERLAY DISPLAYING IMAGE NAME
			set thisTitleBox to ¬
				make new text item with properties {object text:thisImageName}
			tell thisTitleBox
				set font of object text of it to textLabelTypeface
				set size of object text of it to textLabelSize
				set thisItemHeight to its height
				set thisItemWidth to its width
				-- place above smaller image
				set thisOffsetPercentageFactor to textLabelOffsetPercentage * 0.01
				set position of it to ¬
					{(screenWidth - thisItemWidth) div 2 ¬
						, ((screenHeight div 4) - (thisItemHeight * thisOffsetPercentageFactor))}
			end tell
			-- lock all of the items
			set locked of every iWork item to true
		end tell
	end tell
	
	-- START PLAYING THE PRESENTATION FROM THE BEGINNING
	start thisDocument from first slide of thisDocument
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
