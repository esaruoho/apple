tell application "Keynote"
	activate
	tell the front document
		tell the current slide
			
			-- TO REPLACE A PLACEHOLDER OR EXISTING IMAGE:
			-- change the value of the “file name” property of the image to be an HFS file reference to the replacement image file
			set thisPlaceholderImageItem to image 1
			set file name of thisPlaceholderImageItem to ¬
				alias "Macintosh HD:Users:sal:Pictures:Saturn.jpg"
			
		end tell
	end tell
end tell
