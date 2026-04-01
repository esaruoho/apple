property offsetPadding : 8
property textTypeface : "Helvetica Neue Medium"
property textFontSizeFixed : 24
property textFontSizeLarge : 36
property textFontSizeMedium : 24
property textFontSizeSmall : 18
property textRGBColorValues : {65535, 65535, 65535}

tell application "Keynote"
	activate
	if playing is true then tell the front document to stop
	
	if not (exists document 1) then error number -128
	
	tell front document
		set documentWidth to its width
		set documentHeight to its height
		
		display dialog "Add descriptions below images on all slides, or just the current slide?" buttons {"Cancel", "All Slides", "Current Slide"} default button 3 with icon 1
		set targetScope to button returned of the result
		log ("targetScope: " & targetScope)
		if the targetScope is "All Slides" then
			set theseSlides to every slide whose skipped is false
		else
			set theseSlides to {}
			set the end of theseSlides to the current slide
		end if
		
		display dialog "Use fixed or adjustable size for the font size?" buttons {"Cancel", "Adjustable", "Fixed"} default button 3 with icon 1
		set fontSizeMethod to the button returned of the result
		log ("fontSizeMethod: " & fontSizeMethod)
		
		repeat with i from 1 to the count of theseSlides
			set thisSlide to item i of theseSlides
			set imageCount to the count of images of thisSlide
			repeat with q from 1 to the imageCount
				set thisImage to image q of thisSlide
				set thisDescription to the description of thisImage
				if thisDescription is not "" then
					copy (my deriveBoundsOfVisibleImageMaskFor(thisImage)) to {x, y, x1, y1}
					tell thisSlide
						set thisTextItem to make new text item with properties {position:{x, y}, width:(x1 - x), object text:thisDescription}
					end tell
					tell thisTextItem
						tell object text
							set font to textTypeface
							if fontSizeMethod is "Adjustable" then
								set fontSizeFactor to (x1 - x) div (length of thisDescription)
								log "fontSizeFactor: " & fontSizeFactor
								if fontSizeFactor is less than 25 then
									set textFontSize to textFontSizeSmall
								else if fontSizeFactor is less than 35 then
									set textFontSize to textFontSizeMedium
								else
									set textFontSize to textFontSizeLarge
								end if
							else
								set textFontSize to textFontSizeFixed
							end if
							set size to textFontSize
							-- Always use “of it” when setting the value of the color property
							set color of it to textRGBColorValues
						end tell
						-- position the text item below the host image
						set textItemHeight to its height
						copy its position to {tx, ty}
						set its position to {tx, (y1 + offsetPadding)}
					end tell
				end if
			end repeat
		end repeat
	end tell
end tell

on deriveBoundsOfVisibleImageMaskFor(thisImage)
	tell application "Keynote"
		tell front document
			set documentWidth to its width
			set documentHeight to its height
			
			copy position of thisImage to {imageMaskTopLeftHorizontalOffset, imageMaskTopLeftVerticalOffset}
			set imageMaskWidth to width of thisImage
			set imageMaskHeight to height of thisImage
			
			-- derive the top left horizontal offset of the visible image mask
			if imageMaskTopLeftHorizontalOffset is less than 0 then
				set visbleImageMaskTopLeftHorizontalOffset to 0
			else
				set visbleImageMaskTopLeftHorizontalOffset to imageMaskTopLeftHorizontalOffset
			end if
			
			-- derive the bottom right horizontal offset of the visible image mask
			set imageMaskBottomRightHorizontalOffset to imageMaskTopLeftHorizontalOffset + imageMaskWidth
			if imageMaskBottomRightHorizontalOffset is greater than documentWidth then
				set visbleImageMaskBottomRightHorizontalOffset to documentWidth
			else
				set visbleImageMaskBottomRightHorizontalOffset to imageMaskBottomRightHorizontalOffset
			end if
			
			-- derive the width of the visible image mask
			set visbleImageMaskWidth to visbleImageMaskBottomRightHorizontalOffset - visbleImageMaskTopLeftHorizontalOffset
			
			log "visbleImageMaskWidth: " & visbleImageMaskWidth
			
			-- derive the top left vertical offset of the visible image mask
			if imageMaskTopLeftVerticalOffset is less than 0 then
				set visbleImageMaskTopLeftVerticalOffset to 0
			else
				set visbleImageMaskTopLeftVerticalOffset to imageMaskTopLeftVerticalOffset
			end if
			
			log "visbleImageMaskTopLeftVerticalOffset: " & visbleImageMaskTopLeftVerticalOffset
			
			-- derive the bottom right vertical offset of the visible image mask
			set imageMaskBottomRightVerticalOffset to imageMaskTopLeftVerticalOffset + imageMaskHeight
			if imageMaskBottomRightVerticalOffset is greater than documentHeight then
				set visibleImageMaskBottomRightVerticalOffset to documentHeight
			else
				set visibleImageMaskBottomRightVerticalOffset to imageMaskBottomRightVerticalOffset
			end if
			
			log "visibleImageMaskBottomRightVerticalOffset: " & visibleImageMaskBottomRightVerticalOffset
			
			-- derive the height of the visible image mask
			set visbleImageMaskHeight to visibleImageMaskBottomRightVerticalOffset - visbleImageMaskTopLeftVerticalOffset
			
			log "visbleImageMaskHeight: " & visbleImageMaskHeight
			
			-- return bounds of the visible image mask
			return {visbleImageMaskTopLeftHorizontalOffset, visbleImageMaskTopLeftVerticalOffset, visbleImageMaskBottomRightHorizontalOffset, visibleImageMaskBottomRightVerticalOffset}
		end tell
	end tell
end deriveBoundsOfVisibleImageMaskFor
