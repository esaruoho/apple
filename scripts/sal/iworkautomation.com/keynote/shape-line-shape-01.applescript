tell application "Keynote"
	activate
	if not (exists document 1) then error number -128
	tell the front document
		set documentWidth to its width
		set documentHeight to its height
		tell the current slide
			set thisShape to ¬
				make new shape with properties ¬
					{position:{0, 0} ¬
						, width:documentWidth ¬
						, height:documentHeight ¬
						, opacity:100}
		end tell
	end tell
end tell
