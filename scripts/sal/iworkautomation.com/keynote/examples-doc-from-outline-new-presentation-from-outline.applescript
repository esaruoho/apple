property defaultTransitionDuration : 0.5
property defaultTransitionDelay : 2.0
property defaultAutomaticTransition : true

tell application "OmniOutliner"
	activate
	
	set dialogParagraphBreak to return & return
	display dialog "This script will create a new Keynote document based on the content of the frontmost OmniOutliner document." & dialogParagraphBreak & "Each section head of the OmniOutliner document will be used as the title for a new slide in the Keynote document." & dialogParagraphBreak & "If a section contains no children, the “Title - Center” master will be used." & dialogParagraphBreak & "If a section contains one child, the “Title & Subtitle” master will be used, with the name of the child becoming the subtitle." & dialogParagraphBreak & "If a section contains more than one child, the “Title & Bullets” master will be used, and the section’s children will become the bullet points for the created slide." & dialogParagraphBreak & "The new slideshow will automatically play from the beginning and auto-advance." with icon 1
	
	if not (exists document 1) then error number -128
	
	tell front document
		set the slideCount to the count of sections
	end tell
end tell

tell application "Keynote"
	activate
	
	set the themeNames to the name of every theme
	
	set the chosenTheme to ¬
		(choose from list themeNames with prompt ¬
			"Choose a theme to use:" default items (item 1 of themeNames))
	
	if chosenTheme is false then error number -128
	
	set dialogMessage to "Standard Size or Widescreen?"
	display dialog dialogMessage buttons {"Cancel", "Standard", "Widescreen"} default button 3
	if the button returned of the result is "Standard" then
		set targetWidth to 1024 -- 1440 <-- higher resolution
		set targetHeight to 768 -- 1080 <-- higher resolution
	else
		set targetWidth to 1920
		set targetHeight to 1080
	end if
	
	set thisDocument to ¬
		make new document with properties ¬
			{document theme:theme (chosenTheme as string), width:targetWidth, height:targetHeight}
end tell

tell application "OmniOutliner"
	tell front document
		repeat with i from 1 to the count of sections
			tell section i
				set thisSectionText to name of it
				repeat with q from 1 to the count of children
					tell child q
						set thisSectionText to thisSectionText & return & name of it
						set the childCount to the count of children
						if the childCount is not 0 then
							-- 2nd-level bullets
							repeat with z from 1 to the childCount
								set thisSectionText to thisSectionText & return & tab & name of child z
							end repeat
						end if
					end tell
				end repeat
			end tell
			set the paragraphCount to the count of paragraphs of thisSectionText
			if paragraphCount is 1 then
				set the masterSlideName to "Title - Center"
				set thisSlideTitle to thisSectionText
				set thisSlideBody to ""
			else if paragraphCount is 2 then
				set the masterSlideName to "Title & Subtitle"
				set thisSlideTitle to the first paragraph of thisSectionText
				set thisSlideBody to the second paragraph of thisSectionText
			else if paragraphCount is greater than or equal to 3 then
				set the masterSlideName to "Title & Bullets"
				set thisSlideTitle to the first paragraph of thisSectionText
				set thisSlideBodyElements to paragraphs 2 thru -1 of thisSectionText
				set AppleScript's text item delimiters to return
				set thisSlideBody to thisSlideBodyElements as string
				set AppleScript's text item delimiters to ""
			end if
			my createSlide(masterSlideName, thisSlideTitle, thisSlideBody)
		end repeat
	end tell
end tell

tell application "Keynote"
	activate
	
	tell thisDocument to delete slide 1
	
	start thisDocument from first slide of thisDocument
end tell

on createSlide(masterSlideName, thisSlideTitle, thisSlideBody)
	try
		tell application "Keynote"
			tell front document
				set thisSlide to make new slide with properties {base slide:master slide masterSlideName}
				tell thisSlide
					set the transition properties to ¬
						{transition effect:dissolve, transition duration:defaultTransitionDuration, transition delay:defaultTransitionDelay, automatic transition:defaultAutomaticTransition}
					if title showing is true then
						set the object text of the default title item to thisSlideTitle
					end if
					if body showing is true then
						set the object text of the default body item to thisSlideBody
					end if
				end tell
			end tell
		end tell
		return true
	on error
		return false
	end try
end createSlide
