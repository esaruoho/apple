tell application "Keynote"
	tell front document
		my goToSlideByIndex(-1) -- last slide is: -1
		delay 2
		my goToSlideByReference(the first slide)
	end tell
end tell

on goToSlideByIndex(slideIndex)
	tell application "Keynote"
		activate
		tell the front document
			tell slide slideIndex
				set thisShape to ¬
					make new shape with properties ¬
						{height:12, width:12, position:{0, 0}}
				delete thisShape
			end tell
		end tell
	end tell
end goToSlideByIndex

on goToSlideByReference(slideReference)
	tell application "Keynote"
		activate
		tell the front document
			tell slideReference
				set thisShape to ¬
					make new shape with properties ¬
						{height:12, width:12, position:{0, 0}}
				delete thisShape
			end tell
		end tell
	end tell
end goToSlideByReference
