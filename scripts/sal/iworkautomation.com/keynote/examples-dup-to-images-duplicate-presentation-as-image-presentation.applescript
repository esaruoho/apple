tell application "Keynote"
	activate
	if playing is true then tell the front document to stop
	
	if not (exists document 1) then error number -128
	
	display dialog "This script will export the front presentation as images and then create a new presentation containing the exported images." & return & return & "Slide transitions and presenter notes will be transfered from the source presentation." with icon 1
	
	-- STORE INFORMATION ABOUT FRONT DOCUMENT
	tell front document
		set documentName to its name
		set documentWidth to its width
		set documentHeight to its height
		set the slideCount to the count of (every slide whose skipped is false)
	end tell
	
	-- CREATE AN EXPORT DESTINATION FOLDER
	-- IMPORTANT: IT’S ADVISED TO ALWAYS CREATE A NEW DESTINATION FOLDER, AS THE CONTENTS OF ANY TARGETED FOLDER WILL BE OVERWRITTEN
	tell application "Finder"
		set the targetFolder to (make new folder at desktop)
		set the targetFolderHFSPath to targetFolder as string
	end tell
	
	-- EXPORT THE FRONT DOCUMENT TO IMAGES
	export the front document as slide images to file targetFolderHFSPath with properties {image format:PNG, skipped slides:false, export style:IndividualSlides}
	
	-- SORT THE IMAGE FILES BY NAME AND CONVERT TO FILE REFERENCES
	tell application "Finder"
		set theseItems to every document file of the targetFolder
		set theseItems to sort theseItems by name
		set theseImageFiles to {}
		repeat with i from 1 to the count of theseItems
			set the end of theseImageFiles to (item i of theseItems) as alias
		end repeat
	end tell
	
	-- MAKE A NEW PRESENTATION
	set newPresentation to make new document with properties {document theme:theme "Black", width:documentWidth, height:documentHeight}
	tell newPresentation
		set blankMasterSlide to master slide "Blank"
		set the base slide of slide 1 to blankMasterSlide
		-- IMPORT THE IMAGE FILES
		repeat with i from 1 to the count of theseImageFiles
			set thisImageFile to item i of theseImageFiles
			if i is 1 then
				tell slide 1
					set thisImage to make new image with properties {file:thisImageFile}
					set locked of thisImage to true
				end tell
			else
				set thisSlide to make new slide with properties {base slide:blankMasterSlide}
				tell thisSlide
					set thisImage to make new image with properties {file:thisImageFile}
					set locked of thisImage to true
				end tell
			end if
		end repeat
	end tell
	
	-- DELETE THE TEMPORARY FOLDER
	tell application "Finder"
		delete targetFolder
	end tell
	
	-- TRANSFER TRANSITION SETTINGS AND PRESENTER NOTES
	repeat with i from 1 to slideCount
		tell document 2
			set sourceSlide to (the first slide whose slide number is i)
			set theseTransitionProperties to transition properties of sourceSlide
			set thesePresenterNotes to the presenter notes of sourceSlide
		end tell
		tell front document
			set transition properties of slide i to theseTransitionProperties
			set presenter notes of slide i to thesePresenterNotes
		end tell
	end repeat
	
	-- PLAY THE NEW PRESENTATION
	start the front document from the first slide of the front document
end tell
