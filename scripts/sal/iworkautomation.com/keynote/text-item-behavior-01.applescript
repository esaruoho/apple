tell application "Keynote"
	activate
	set thisDocument to ¬
		make new document with properties {document theme:theme "Black"}
	tell thisDocument
		set the base slide of the first slide to master slide "Title & Subtitle"
		tell first slide
			-- set the title
			set the object text of the default title item to "TITLE"
			-- set the subtitle
			set the object text of the default body item to "BODY SUBTITLE"
		end tell
		set thisSlide to ¬
			make new slide with properties {base slide:master slide "Title & Bullets"}
		tell thisSlide
			-- set the title
			set the object text of the default title item to "TITLE"
			-- set a bullet list
			set the object text of the default body item to ¬
				"Bullet Point 1" & return & "Bullet Point 2" & return & "Bullet Point 3"
		end tell
	end tell
end tell
