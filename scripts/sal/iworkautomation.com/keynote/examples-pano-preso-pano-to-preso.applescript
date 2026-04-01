property transitionInOutDuration : 3
property transitionPanDuration : 10
property transitionInOutDelay : 2

tell application "Keynote"
	if playing is true then tell the front document to stop
	activate
	
	set the sourcePanoImage to ¬
		(choose file of type "public.image" with prompt ¬
			"Pick the panoramic image to place across two slides:")
	
	set thisDocument to make new document with properties ¬
		{document theme:theme "Black", width:1920, height:1080}
	
	tell thisDocument
		-- get dimensions of the current document
		set documentHeight to its height
		set documentWidth to its width
		
		-- set the master slide of the first slide
		set the base slide of slide 1 to master slide "Blank"
		
		tell slide 1
			-- set transition to Magic Move
			set the transition properties to ¬
				{transition effect:magic move ¬
					, transition duration:transitionInOutDuration ¬
					, transition delay:transitionInOutDelay ¬
					, automatic transition:true}
			-- import the pano image
			set thisImage to ¬
				make new image with properties {file:sourcePanoImage}
		end tell
		
		-- create a second slide
		set secondSlide to ¬
			make new slide with properties {base slide:master slide "Blank"}
		tell secondSlide
			-- set transition to Magic Move
			set the transition properties to ¬
				{transition effect:magic move ¬
					, transition duration:transitionPanDuration ¬
					, transition delay:0 ¬
					, automatic transition:true}
			-- import the pano image
			set thisImage to ¬
				make new image with properties {file:sourcePanoImage}
			-- scale the image to match slide height and position so the left side of the image aligns with the left side of the slide
			tell thisImage
				set height to documentHeight
				set position to {0, 0}
			end tell
		end tell
		
		-- create a third slide
		set thirdSlide to ¬
			make new slide with properties {base slide:master slide "Blank"}
		tell thirdSlide
			-- set transition to Magic Move
			set the transition properties to ¬
				{transition effect:magic move ¬
					, transition duration:transitionInOutDuration ¬
					, transition delay:transitionInOutDelay ¬
					, automatic transition:true}
			-- import the pano image
			set thisImage to ¬
				make new image with properties {file:sourcePanoImage}
			-- scale the image to match slide height and position so the right side of the image aligns with the right side of the slide
			tell thisImage
				set height to documentHeight
				set imageWidth to its width
				set position to {documentWidth - imageWidth, 0}
			end tell
		end tell
		
		-- create a fourth slide
		set fourthSlide to ¬
			make new slide with properties {base slide:master slide "Blank"}
		tell fourthSlide
			-- import the pano image
			set thisImage to ¬
				make new image with properties {file:sourcePanoImage}
		end tell
		
	end tell
	
	start thisDocument from first slide of thisDocument
	
end tell
