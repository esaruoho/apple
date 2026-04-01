tell application "Keynote"
	activate
	set thisDocument to ¬
		make new document with properties ¬
			{document theme:theme "Black", width:1024, height:768}
	tell thisDocument
		set base slide of the first slide to master slide "Blank"
		set the documentWidth to its width
		tell the first slide
			-- Make simple text item
			set thisTextItem to ¬
				make new text item with properties {object text:"HELLO"}
			delay 5
			-- Change the object text, text item expands, stays centered
			set object text of thisTextItem to "HOW NOW BROWN COW"
			delay 5
			-- Change object text to trigger default wrapping and sizing behavior
			set object text of thisTextItem to "Integer posuere erat a ante venenatis dapibus posuere velit aliquet. Praesent commodo cursus magna, vel scelerisque nisl consectetur et. Cras justo odio, dapibus ac facilisis in, egestas eget quam. Integer posuere erat a ante venenatis dapibus posuere velit aliquet. Sed posuere consectetur est at lobortis. Cras mattis consectetur purus sit amet fermentum."
			delay 5
			-- Change the width of the text item. Note item does not auto-center.
			set the width of thisTextItem to (documentWidth * 0.75)
			delay 5
			-- Get the current position of the text item
			copy the position of thisTextItem to {thisHorizontalValue, thisVerticalValue}
			-- Adjust postion to be centered, keeping the current vertical offset.
			set position of thisTextItem to {(documentWidth * 0.25) div 2, thisVerticalValue}
		end tell
	end tell
end tell
