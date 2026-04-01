on trim_paragraphs(this_text, trim_chars, trim_indicator)
	set the paragraph_list to every paragraph of this_text
	repeat with i from 1 to the count of paragraphs of this_text
		set this_paragraph to item i of the paragraph_list
		set item i of the paragraph_list to trim_line(this_paragraph, trim_chars, trim_indicator)
	end repeat
	set AppleScript's text item delimiters to return
	set this_text to the paragraph_list as string
	set AppleScript's text item delimiters to ""
	return this_text
end trim_paragraphs
