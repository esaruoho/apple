property thisThemeName : "Image Grid Kiosk"
property gridSlideMasterName : "Photo - Grid 28"
property photoSlideMasterName : "Photo"
property squarePhotoSlideMasterName : "Photo - Square"

property defaultAutomaticTransistion : true
property defaultImageDisplayTime : 3

tell application "Keynote"
	activate
	
	if playing is true then tell the front document to stop
	
	try
		-- check for the required theme
		set the templateNames to the name of every theme
		if thisThemeName is not in the templateNames then error number 1000
		
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
		
		display dialog "Enter the title for the presentation:" default answer ""
		set the presentationTitle to the text returned of the result
		
		set thisDocument to ¬
			make new document with properties {document theme:theme thisThemeName}
		
		tell thisDocument
			-- SET THE TITLE SLIDE
			tell the current slide
				set base slide to master slide "Title - Center" of thisDocument
				set the object text of the default title item to the presentationTitle
				-- set slide transition
				set the transition properties to ¬
					{transition effect:dissolve ¬
						, transition duration:2 ¬
						, transition delay:3 ¬
						, automatic transition:defaultAutomaticTransistion}
			end tell
			
			-- MAKE THE GRID SLIDE
			set gridSlide to make new slide with properties {base slide:master slide gridSlideMasterName}
			tell gridSlide
				-- set slide transition
				set the transition properties to ¬
					{transition effect:magic move ¬
						, transition duration:2 ¬
						, transition delay:0 ¬
						, automatic transition:defaultAutomaticTransistion}
				-- populate the image placeholders
				set the gridCount to the count of images
				set theseImagePaths to items 1 thru gridCount of the imagePaths
				repeat with i from 1 to the gridCount
					set thisImageFile to (item i of theseImagePaths) as POSIX file
					set the file name of image i to thisImageFile
				end repeat
			end tell
			delay 1
			
			-- ADD THE RELATED SLIDES FOR EACH IMAGE
			repeat with i from 1 to the count of theseImagePaths
				set thisImageFile to (item i of theseImagePaths) as POSIX file
				my addInboundSquarePhotoSlide(thisImageFile)
				my addPhotoSlide(thisImageFile)
				my addOutboundSquarePhotoSlide(thisImageFile)
				delay 1
				duplicate slide 2 to after last slide
				delay 1
			end repeat
			
			-- SET GRID SLIDE TO DISPLAY LONGER
			tell gridSlide
				set the transition properties to {transition delay:2}
			end tell
			
			-- SET THE KIOSK PROPERTIES
			set auto play to true
			set auto loop to true
		end tell
		
		-- START THE PRESENTATION
		start thisDocument from first slide of thisDocument
		
	on error errorMessage number errorNumber
		if errorNumber is 1000 then
			display alert "MISSING RESOURCE" message "This script requires the installation of a Keynote theme titled “" & thisThemeName & ".”" & return & return & "The template can be downloaded from: iworkautomation.com" as critical buttons {"Download", "Stop"} default button 2
			if the button returned of the result is "Download" then
				open location "http://iworkautomation.com/keynote/examples-grid-kiosk.html"
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

on addInboundSquarePhotoSlide(thisImageFile)
	tell application "Keynote"
		tell front document
			set thisSlide to ¬
				make new slide with properties ¬
					{base slide:master slide squarePhotoSlideMasterName}
			tell thisSlide
				set the file name of the first image to thisImageFile
				set the transition properties to ¬
					{transition effect:dissolve ¬
						, transition duration:0.5 ¬
						, transition delay:0 ¬
						, automatic transition:defaultAutomaticTransistion}
			end tell
		end tell
	end tell
end addInboundSquarePhotoSlide

on addOutboundSquarePhotoSlide(thisImageFile)
	tell application "Keynote"
		tell front document
			set thisSlide to ¬
				make new slide with properties ¬
					{base slide:master slide squarePhotoSlideMasterName}
			tell thisSlide
				set the file name of the first image to thisImageFile
				set the transition properties to ¬
					{transition effect:magic move ¬
						, transition duration:1.5 ¬
						, transition delay:0 ¬
						, automatic transition:defaultAutomaticTransistion}
			end tell
		end tell
	end tell
end addOutboundSquarePhotoSlide

on addPhotoSlide(thisImageFile)
	tell application "Keynote"
		tell front document
			set documentWidth to its width
			set documentHeight to its height
			set thisSlide to make new slide with properties {base slide:master slide "Blank"}
			tell thisSlide
				set thisImage to make new image with properties {file:thisImageFile}
				tell thisImage
					set its height to documentHeight
					set its position to {(documentWidth - (its width)) div 2, 0}
				end tell
				set the transition properties to ¬
					{transition effect:dissolve, transition duration:0.5 ¬
						, transition delay:defaultImageDisplayTime ¬
						, automatic transition:defaultAutomaticTransistion}
			end tell
		end tell
	end tell
end addPhotoSlide

on duplicateSlideToEnd(thisSlide)
	tell application "Keynote"
		tell front document
			duplicate thisSlide to after last slide
		end tell
	end tell
end duplicateSlideToEnd
