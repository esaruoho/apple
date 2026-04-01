tell application "Keynote"
	activate
	tell the front document
		tell the current slide
			
			-- TO CREATE A NEW IMAGE ITEM:
			-- use the make command and include an HFS file reference to the file to be imported, as the value of “file” property
			set newImageItem to ¬
				make new image with properties ¬
					{file:alias "Macintosh HD:Users:sal:Pictures:NASA Rocket.jpg"}
			
		end tell
	end tell
end tell
