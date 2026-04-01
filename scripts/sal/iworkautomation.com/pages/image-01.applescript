property templateName : "Photo Card Horizontal"
property templateWidth : 792
property templateHeight : 612
property defaultMargin : 36
property textItemInset : 12
property defaultTypeFace : "Verdana"
property defaultTypeSize : 10

tell application "Pages"
	activate
	
	-- promput user for images
	set theseImages to ¬
		(choose file with prompt "Select the images to import:" with multiple selections allowed)
	
	-- make a new page layout document
	set thisDocument to make new document with properties ¬
		{document template:template templateName}
	
	tell thisDocument
		-- delete the default template items
		set locked of every iWork item to false
		delete every iWork item
		
		-- add the images to the document, each on its own page
		repeat with i from 1 to the count of theseImages
			set thisImageFile to item i of theseImages
			-- extract any embedded caption metadata from the image file
			set thisImageDescription to my extractkMDItemDescription(thisImageFile)
			-- make a new page if needed
			if i is not 1 then make new page
			tell current page
				-- import the image
				set thisImage to make new image with properties {file:thisImageFile}
				-- center the image on the page
				tell thisImage
					copy {width of it, height of it} to {imageWidth, imageHieght}
					set its width to (templateWidth - (defaultMargin * 2))
					copy {width of it, height of it} to {imageWidth, imageHieght}
					set its position to ¬
						{(templateWidth - imageWidth) div 2, (templateHeight - imageHieght) div 2}
				end tell
				-- if there is an image description, place over opaque background overlay
				if thisImageDescription is not "" then
					set thisShape to make new shape with properties ¬
						{width:(templateWidth - (4 * defaultMargin)) ¬
							, height:90 ¬
							, position:{(2 * defaultMargin) ¬
							, (templateHeight - (4 * defaultMargin))} ¬
							, opacity:40}
					tell thisShape
						copy {width of it, height of it} to {shapeWidth, shapeHeight}
						copy its position to {shapeHorizontalOffset, shapeVerticalOffset}
					end tell
					set thisTextItem to make new text item with properties ¬
						{object text:thisImageDescription ¬
							, width:(shapeWidth - (2 * textItemInset)) ¬
							, height:(shapeHeight - (2 * textItemInset)) ¬
							, position:{shapeHorizontalOffset + textItemInset ¬
							, shapeVerticalOffset + textItemInset}}
					tell object text of thisTextItem
						set font to defaultTypeFace
						set size to defaultTypeSize
						set color of it to "white"
					end tell
				end if
			end tell
		end repeat
	end tell
end tell

on extractkMDItemDescription(thisImageFile)
	-- use Spotlight to extract embedded metadata
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
