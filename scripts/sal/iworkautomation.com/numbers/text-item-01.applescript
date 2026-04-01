-- U.S. Letter page dimensions in points
-- (reverse for horizontal layout)
property pageWidth : 612
property pageHeight : 792

property titleTypeSize : 48
property titleTypeface : "Times New Roman"
property titleText : "Wind Power in America"
property titleVerticalOffset : 72

property subTitleTypeSize : 24
property subTitleTypeface : "Times New Roman Italic"
property subTitleText : "A 20-year overview of the use of domestic wind power"

tell application "Numbers"
	activate
	
	-- CREATE NEW DOCUMENT USING ONE OF THE VERTICAL TEMPLATES
	set thisDocument to ¬
		make new document with properties ¬
			{document template:template "Checklist"}
	
	tell thisDocument
		tell active sheet
			-- RESET SHEET TITLE
			set its name to "Untitled"
			
			-- CLEAR THE CANVAS
			delete every iWork item
			
			-- ADD TITLE TEXT ITEM
			set titleTextItem to ¬
				make new text item with properties {object text:titleText}
			-- FORMAT THE TITLE TEXT ITEM
			tell titleTextItem
				tell its object text
					set font to titleTypeface
					set size to titleTypeSize
				end tell
				set titleWidth to its width
				set titleHeight to its height
				set position to ¬
					{(pageWidth - titleWidth) div 2, titleVerticalOffset}
			end tell
			
			-- ADD SUBTITLE TEXT ITEM
			set subtitleTextItem to ¬
				make new text item with properties {object text:subTitleText}
			-- FORMAT THE SUBTITLE TEXT ITEM
			tell subtitleTextItem
				tell its object text
					set font to subTitleTypeface
					set size to subTitleTypeSize
				end tell
				set subtitleWidth to its width
				set position to ¬
					{(pageWidth - subtitleWidth) div 2 ¬
						, (titleVerticalOffset + titleHeight)}
			end tell
		end tell
	end tell
end tell
