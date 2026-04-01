tell application "Pages"
	activate
	set thisDocument to ¬
		make new document with properties {document template:template "Tab Flyer"}
	tell thisDocument
		-- GET ALL TAGS
		set theseTags to the tag of every placeholder text
		
		-- FILTER FOR UNIQUE TAGS
		set uniqueTags to {}
		repeat with i from 1 to the count of theseTags
			set thisTag to item i of theseTags
			if thisTag is not in uniqueTags then
				set the end of uniqueTags to thisTag
			end if
		end repeat
		
		-- PROMPT USER FOR REPLACEMENT TEXT
		repeat with i from 1 to the count of uniqueTags
			set thisTag to item i of uniqueTags
			display dialog "Enter the replacement text for this tag:" & ¬
				return & return & thisTag default answer "" buttons ¬
				{"Cancel", "Skip", "OK"} default button 3
			copy the result to {button returned:buttonPressed, text returned:replacementString}
			if buttonPressed is "OK" then
				set (every placeholder text whose tag is thisTag) to replacementString
			end if
		end repeat
		
		-- PROMPT USER FOR REPLACEMENT IMAGE
		set thisImage to the first image
		set thisImageFile to ¬
			(choose file of type "public.image" with prompt ¬
				"Pick the flyer image:" default location (path to pictures folder))
		set file name of thisImage to thisImageFile
	end tell
end tell
