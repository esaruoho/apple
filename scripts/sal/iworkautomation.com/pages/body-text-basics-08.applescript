tell application "Pages"
	activate
	tell front document
		
		get words 1 thru 2 of the first paragraph of the body text of every section
		-- {{"CHAPTER", "I"}, {"CHAPTER", "II"}, {"CHAPTER", "III"}, {"CHAPTER", "IV"}, {"CHAPTER", "V"}, {"CHAPTER", "VI"}, {"CHAPTER", "VII"}, {"CHAPTER", "VIII"}, {"CHAPTER", "IX"}, {"CHAPTER", "X"}, {"CHAPTER", "XI"}, {"CHAPTER", "XII"}}
		
		-- format the first part of the section title
		tell words 1 thru 2 of the first paragraph of the body text of every section
			set font to "Zapfino"
			set size to 8
			set the color of it to {26214, 26214, 26214}
		end tell
		
		-- format the second part of the section title
		tell words 3 thru -1 of the first paragraph of the body text of every section
			set font to "Times New Roman Italic"
			set size to 18
			set the color of it to {0, 0, 0}
		end tell
		
		-- Format any ending punctuation
		tell the last character of the first paragraph of the body text of every section
			set font to "Times New Roman Italic"
			set size to 18
			set the color of it to {0, 0, 0}
		end tell
		
	end tell
end tell
