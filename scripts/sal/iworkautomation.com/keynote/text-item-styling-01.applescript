tell application "Keynote"
	activate
	
	set thisDocument to ¬
		make new document with properties ¬
			{document theme:theme "Black", width:1920, height:1080}
	
	tell thisDocument
		set documentHeight to its height
		
		set the base slide of the first slide to master slide "Blank"
		
		tell slide 1
			-- create a new text item
			set thisDisplayText to "Abracadabra"
			set thisTextItem to ¬
				make new text item with properties {object text:thisDisplayText}
			tell thisTextItem
				-- set type size
				set the size of its object text to 144
				-- set typeface
				set the font of its object text to "Zapfino"
				-- adjust its vertical positon
				copy its position to {currentHorizontal, currentVertical}
				set its position to {currentHorizontal, documentHeight div 3}
			end tell
		end tell
		
		duplicate slide 1 to after slide 1
		
		tell slide 2
			set thisTextItem to its first text item
			tell thisTextItem
				-- set color
				repeat with i from 1 to the length of thisDisplayText
					set thisRGBColorValue to my generateRandomRGBColorValue()
					set the color of character i of object text to thisRGBColorValue
				end repeat
			end tell
		end tell
		
		set the transition properties of the first slide to ¬
			{transition effect:sparkle, transition duration:2.0 ¬
				, transition delay:1.0, automatic transition:true}
	end tell
	
	start thisDocument from first slide of thisDocument
end tell

on generateRandomRGBColorValue()
	set RedValue to random number from 0 to 65535
	set GreenValue to random number from 0 to 65535
	set BlueValue to random number from 0 to 65535
	return {RedValue, GreenValue, BlueValue}
end generateRandomRGBColorValue
