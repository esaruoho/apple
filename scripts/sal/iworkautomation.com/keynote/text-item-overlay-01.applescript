-- OBJECT TEXT PROPERTIES
property textOverlayString : "DRAFT"
property textOverlayTypeface : "Impact"
property textOverlayFontSize : 144
property textOverlayColorName : "white"
property textOverlayRGBColorValues : {65535, 65535, 65535}
-- red={65535, 0, 0}, white={65535, 65535, 65535}, black={0, 0, 0}
-- to derive custom color value, run following script statement and copy result: 
-- return (choose color default color {65535, 0, 0})

-- TEXT ITEM PROPERTIES
property textOverlayOpacityValue : 20
property textOverlayDefaultPosition : 4
-- 0=center, 1=top left, 2=top right, 3=bottom left, 4=bottom right
property textItemOverlayOffset : 36

tell application "Keynote"
	activate
	if playing is true then tell the front document to stop
	
	if not (exists document 1) then error number -128
	
	set textOverlayDefaultPositionName to item (textOverlayDefaultPosition + 1) of ¬
		{"center", "top left", "top right", "bottom left", "bottom right"}
	
	set dialogText to "Overlay Text: " & textOverlayString & return & ¬
		"Text Color: " & textOverlayColorName & return & ¬
		"Text Size: " & textOverlayFontSize & return & ¬
		"Typeface: " & textOverlayTypeface & return & ¬
		"Text Opacity: " & textOverlayOpacityValue & return & ¬
		"Text Position: " & textOverlayDefaultPositionName
	
	display dialog dialogText & return & return & "Add or Remove text overlays?" buttons ¬
		{"Cancel", "Add", "Remove"} default button 1
	set addDeleteOverlay to the button returned of the result
	
	tell the front document
		set documentWidth to its width
		set documentHeight to its height
		
		if addDeleteOverlay is "Add" then
			repeat with i from 1 to the count of slides
				tell slide i
					set thisTextItem to ¬
						make new text item with properties {object text:textOverlayString}
					tell thisTextItem
						tell object text
							set font to textOverlayTypeface
							set size to textOverlayFontSize
							set color of it to textOverlayRGBColorValues
						end tell
						set textItemWidth to its width
						set textItemHeight to its height
						set opacity to textOverlayOpacityValue
						if textOverlayDefaultPosition is 0 then
							-- center
							set x to (documentWidth - textItemWidth) div 2
							set y to (documentHeight - textItemHeight) div 2
						else if textOverlayDefaultPosition is 1 then
							-- top left
							set x to textItemOverlayOffset
							set y to textItemOverlayOffset
						else if textOverlayDefaultPosition is 2 then
							-- top right
							set x to documentWidth - textItemWidth - textItemOverlayOffset
							set y to textItemOverlayOffset
						else if textOverlayDefaultPosition is 3 then
							-- bottom left
							set x to textItemOverlayOffset
							set y to documentHeight - textItemHeight - textItemOverlayOffset
						else if textOverlayDefaultPosition is 4 then
							-- bottom right
							set x to documentWidth - textItemWidth - textItemOverlayOffset
							set y to documentHeight - textItemHeight - textItemOverlayOffset
						end if
						set position to {x, y}
					end tell
				end tell
			end repeat
		else
			delete (every text item of every slide whose object text of it is textOverlayString)
		end if
	end tell
end tell
