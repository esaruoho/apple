on read_parse(this_file, opening_tag, closing_tag, contents_only)
	try
		set this_file to this_file as text
		set this_file to open for access file this_file
		set the combined_results to ""
		set the open_tag to ""
		repeat
			read this_file before "<" -- start of a tag
			set this_tag to read this_file until ">" -- end of a tag
			-- to make up for a bug in the "read before" command
			if this_tag does not start with "<" then set this_tag to ("<" & this_tag) as string
			-- EXAMINE THE TAG
			if this_tag begins with the opening_tag then
				--store the complete tag, not just the search string
				set the open_tag to this_tag
				-- check for single tag indicator
				if the closing_tag is "" then
					if the combined_results is "" then
						set the combined_results to the combined_results & the open_tag
					else
						set the combined_results to the combined_results & return & the open_tag
					end if
				else
					-- reset the text buffer
					set the text_buffer to ""
					-- extract the contents between the open and close tags
					repeat
						set the text_buffer to the text_buffer & (read this_file before "<") -- start of a tag
						set the tag_buffer to read this_file until ">" -- end of a tag
						-- to make up for a bug in the "read before" command
						if the tag_buffer does not start with "<" then set the tag_buffer to ("<" & the tag_buffer) as string
						-- check for the closing tag
						if the tag_buffer is the closing_tag then
							if contents_only is false then
								set the text_buffer to the open_tag & the text_buffer & the tag_buffer
							end if
							if the combined_results is "" then
								set the combined_results to the combined_results & the text_buffer
							else
								set the combined_results to the combined_results & return & the text_buffer
							end if
							exit repeat
						else
							set the text_buffer to the text_buffer & the tag_buffer
						end if
					end repeat
				end if
			end if
		end repeat
		close access this_file
	on error error_msg number error_num
		try
			close access this_file
		end try
		if error_num is not -39 then return false
	end try
	return the combined_results
end read_parse
