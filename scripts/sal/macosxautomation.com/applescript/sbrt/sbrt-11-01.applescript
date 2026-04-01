-- carriage return and line feed 
property crlf : (ASCII character 13) & (ASCII character 10)
-- this builds the normal HTTP header for regular accrss 
property http_header : "HTTP/1.0 200 0K" & crlf & "Server: MacHTTP" & crlf & "MIME-Version: 1.0" & crlf & "Content-type: text/html" & crlf & crlf
-- the HTML opening 
property HTML_opening : "<HTML>" & return & "<HEAD><TITLE>CGI Results</TITLE></HEAD>" & return & "<BODY BGCOLOR=\"#FFFFFF\"><FONT FACE=\"Geneva\" SIZE=\"-1\">" & return
-- the HTML closing 
property HTML_closing : "</FONT></BODY>" & return & "</HTML>"

on handle CGI request this_request searching for search_string with posted data post_arguments using access method GET_or_POST from address this_client from user user_name using password user_password with user info user_information from server server_application via port server_IP_port executing by this_script_path of content type MIME_type referred by referring_page from browser client_browser using action CGI_path of action type action_type with full request request_data from client IP address client_address with connection ID server_connection from virtual host root_URL
	
	set the form_contents to my process_arguments(post_arguments)
	-- returns a list of form items and their values 
	-- {{"FORMITEM1", "FORMITEM1VALUE"}, {"FORMITEM2", "FORMITEM2VALUE"},etc.} 
	
	-- ACTIONS WITH PROCESSED FORM DATA GO HERE 
	-- this example returns the form items and their values 
	set the body_content to ""
	repeat with i from 1 to the count of the form_contents
		copy item i of the form_contents to {form_item, item_value}
		set the body_content to the body_content & form_item & ": " & item_value & "<BR>" & return
	end repeat
	
	-- return HTML to the user 
	return http_header & HTML_opening & body_content & HTML_closing
end handle CGI request

on process_arguments(arguments_string)
	if the arguments_string contains "&" then -- more than one passed parameter 
		set the parameters_list to my convert2list(arguments_string, "&")
	else -- single passed parameter 
		set the parameters_list to the arguments_string as list
	end if
	--{"PARAMETER=PARAMETER1VALUE", "PARAMETER2=PARAMETER2VALUE"} 
	set parameters_list to my convert_list_elements(parameters_list, "=")
	-- {{"PARAMETER1", "PARAMETER1VALUE"}, {"PARAMETER2", "PARAMETER2VALUE"}} 
	repeat with i from 1 to the count of the parameters_list
		copy item i of the parameters_list to {this_parameter, this_value}
		set this_parameter to decode_text(this_parameter)
		set this_value to decode_text(this_value)
		set this_parameter to replace_chars(this_parameter, "+", " ")
		set this_value to replace_chars(this_value, "+", " ")
		set item i of the parameters_list to {this_parameter, this_value}
	end repeat
	return parameters_list
end process_arguments

on convert2list(this_string, this_delimiter)
	set AppleScript's text item delimiters to this_delimiter
	set the item_list to every text item of this_string
	set AppleScript's text item delimiters to ""
	return item_list
end convert2list

on convert_list_elements(this_list, this_delimiter)
	set AppleScript's text item delimiters to this_delimiter
	repeat with i from 1 to the count of the this_list
		set this_item to item i of the this_list
		set this_item to every text item of this_item
		set item i of the this_list to this_item
	end repeat
	set AppleScript's text item delimiters to ""
	return this_list
end convert_list_elements

on list2string(this_list, this_delimiter)
	set AppleScript's text item delimiters to this_delimiter
	set this_string to this_list as string
	set AppleScript's text item delimiters to ""
	return this_string
end list2string

on decode_text(this_text)
	set flag_A to false
	set flag_B to false
	set temp_char to ""
	set the character_list to {}
	repeat with this_char in this_text
		set this_char to the contents of this_char
		if this_char is "%" then
			set flag_A to true
		else if flag_A is true then
			set the temp_char to this_char
			set flag_A to false
			set flag_B to true
		else if flag_B is true then
			set the end of the character_list to my decode_chars(("%" & temp_char & this_char) as string)
			set the temp_char to ""
			set flag_A to false
			set flag_B to false
		else
			set the end of the character_list to this_char
		end if
	end repeat
	return the character_list as string
end decode_text

-- this sub-routine is used to decode a hex string 
on decode_chars(these_chars)
	copy these_chars to {indentifying_char, multiplier_char, remainder_char}
	set the hex_list to "123456789ABCDEF"
	if the multiplier_char is in "ABCDEF" then
		set the multiplier_amt to the offset of the multiplier_char in the hex_list
	else
		set the multiplier_amt to the multiplier_char as integer
	end if
	if the remainder_char is in "ABCDEF" then
		set the remainder_amt to the offset of the remainder_char in the hex_list
	else
		set the remainder_amt to the remainder_char as integer
	end if
	set the ASCII_num to (multiplier_amt * 16) + remainder_amt
	return (ASCII character ASCII_num)
end decode_chars

on replace_chars(this_text, search_string, replacement_string)
	set AppleScript's text item delimiters to the search_string
	set the item_list to every text item of this_text
	set AppleScript's text item delimiters to the replacement_string
	set this_text to the item_list as string
	set AppleScript's text item delimiters to ""
	return this_text
end replace_chars
