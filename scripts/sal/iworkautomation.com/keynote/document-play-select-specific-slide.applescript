tell application "Keynote"
	activate
	if not (exists document 1) then error number -128
	tell document 1
		my moveToSlide(last slide)
		delay 2
		my moveToSlide(first slide)
	end tell
end tell

on moveToSlide(thisSlide)
	tell application "Keynote"
		tell front document
			if thisSlide is last slide then
				start from slide before last slide
				tell application "Keynote"
					show slide switcher
					move slide switcher forward
					accept slide switcher
					stop front document
				end tell
			else
				set thisSlideNumber to slide number of thisSlide
				start from slide (thisSlideNumber + 1)
				tell application "Keynote"
					show slide switcher
					move slide switcher backward
					accept slide switcher
					stop front document
				end tell
			end if
		end tell
	end tell
end moveToSlide
