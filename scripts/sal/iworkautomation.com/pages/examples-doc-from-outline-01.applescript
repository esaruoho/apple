property defaultTemplateName : "Blank"

property defaultDocumentTitleTypeSize : 32
property defaultDocumentTitleTypeFace : "Hoefler Text"
property defaultDocumentTitleTypeColor : "black"

property defaultSectionTypeFace : "Times New Roman Italic"
property defaultSectionTypeSize : 18
property defaultSectionTypeColor : "black"

property defaultBodyTypeFace : "Hoefler Text"
property defaultBodyTypeSize : 12
property defaultBodyTypeColor : "gray"

property defaultTOCTitleTypeFace : "Helvetica"
property defaultTOCTitleTypeSize : 22
property defaultTOCTitleTypeColor : "black"

property defaultTOCItemTypeFace : "Hoefler Text"
property defaultTOCItemTypeSize : 18
property defaultTOCItemTypeColor : "gray"

property useSectionTitleForTOC : true


tell application "OmniOutliner"
	activate
	display dialog "This script will create a new Pages word-processing document, with each section of the frontmost OmniOutliner document becoming a new section in the Pages document." & return & return & "The name of each OmniOutliner section will be used as both the title of the newly created Pages section, and as an entry in the optionally created Table of Contents." with icon 1 buttons {"Cancel", "Include TOC", "Build"} default button 3
	if button returned of the result is "Include TOC" then
		set createTOC to true
	else
		set createTOC to false
	end if
	if not (exists document 1) then error number -128
	tell front document
		set sourceDocumentTitle to its name
		set the sourceDocumentSectionNames to the name of every section
		set the sourceDocumentSectionCount to ¬
			the count of the sourceDocumentSectionNames
	end tell
end tell

tell application "Pages"
	activate
	set thisDocument to ¬
		make new document with properties ¬
			{document template:template defaultTemplateName}
	
	tell thisDocument
		
		if document body is false then
			display alert "INCOMPATIBLE TEMPLATE" message "The template of this document does not have an active document body text flow."
			error number -128
		end if
		
		-- TITLE PAGE
		tell page 1
			set body text to sourceDocumentTitle
			tell body text
				set font to defaultDocumentTitleTypeFace
				set size to defaultDocumentTitleTypeSize
				set the color of it to defaultDocumentTitleTypeColor
			end tell
		end tell
		
		-- TOC PAGE OPTION
		if createTOC is true then
			make new section
			set bufferIndex to 2
		else
			set bufferIndex to 1
		end if
		
		-- MAKE THE SECTIONS
		repeat with i from 1 to (sourceDocumentSectionCount)
			make new section
		end repeat
		
		-- POPULATE THE CONTENT OF THE SECTIONS
		repeat with i from 1 to sourceDocumentSectionCount
			tell application "OmniOutliner"
				tell front document
					tell section i
						set thisSourceDocumentSectionsText to name of it
						set the leavesNames to the name of leaves
						set thisSourceDocumentSectionsText to ¬
							thisSourceDocumentSectionsText & return & ¬
							return & my textItemsToText(leavesNames)
					end tell
				end tell
			end tell
			set pagesSectionIndex to (i + bufferIndex)
			set body text of section pagesSectionIndex to thisSourceDocumentSectionsText
			tell section pagesSectionIndex
				tell body text
					repeat with i from 1 to the count of paragraphs
						if i is 1 then
							set color of paragraph i to defaultSectionTypeColor
							tell paragraph i
								set font to defaultSectionTypeFace
								set size to defaultSectionTypeSize
							end tell
						else
							set color of paragraph i to defaultBodyTypeColor
							tell paragraph i
								set font to defaultBodyTypeFace
								set size to defaultBodyTypeSize
							end tell
						end if
					end repeat
				end tell
			end tell
		end repeat
		
		-- CREATE THE TOC
		if createTOC is true then
			set x to 2 -- title and TOC
			set sectionStartIndexes to {}
			set sectionTitleCounter to 1
			set sectionDisplayNumber to 1
			repeat with i from 2 to the count of sections
				set the sectionStartPageIndex to x
				set the end of the sectionStartIndexes to sectionStartPageIndex
				if i is 2 then
					set TOCText to "TABLE OF CONTENTS" & return
				else
					if useSectionTitleForTOC is true then
						set TOCText to TOCText & return & tab & ¬
							(item sectionTitleCounter of sourceDocumentSectionNames) & ¬
							tab & sectionStartPageIndex
						set sectionTitleCounter to sectionTitleCounter + 1
					else
						set TOCText to TOCText & return & tab & ¬
							(item sectionTitleCounter of sourceDocumentSectionNames) & ¬
							tab & sectionStartPageIndex
						set sectionTitleCounter to sectionTitleCounter + 1
					end if
				end if
				set x to x + (count of pages of section i)
			end repeat
			set body text of section 2 to TOCText
			-- FROMAT THE TOC
			tell body text of section 2
				tell paragraph 1
					set font to defaultTOCTitleTypeFace
					set size to defaultTOCTitleTypeSize
					set color of it to defaultTOCTitleTypeColor
				end tell
				tell paragraphs 2 thru -1
					set font to defaultTOCItemTypeFace
					set size to defaultTOCItemTypeSize
					set color of it to defaultTOCItemTypeColor
				end tell
			end tell
		end if
	end tell
end tell
my goToPage(1)
my displayThisNotification("OmniOutliner to Pages", "Document created.", "")

on textItemsToText(textItems)
	set AppleScript's text item delimiters to (return & return) -- double spaced 
	set the textBlock to textItems as string
	set AppleScript's text item delimiters to ""
	return textBlock
end textItemsToText

on displayThisNotification(thisTitle, thisNotification, thisSubtitle)
	tell current application
		display notification thisNotification with title thisTitle subtitle thisSubtitle
	end tell
end displayThisNotification

on goToPage(pageIndex)
	tell application "Pages"
		activate
		tell the front document
			tell page pageIndex
				set thisShape to ¬
					make new shape with properties ¬
						{height:12, width:12, position:{0, 0}}
				delete thisShape
			end tell
		end tell
	end tell
end goToPage
