tell application "Pages"
	activate
	display dialog "This script will replace all occurences of “Alice” and “Alice's” with “Wanda” and “Wanda's” in the “Alice in Wonderland” example Pages document." with icon 1 buttons {"Cancel", "Download Document", "Begin"} default button 3
	if the button returned of the result is "Download Document" then
		open location "http://iworkautomation.com/pages/body-text-replace.html"
	else
		my replaceWordWithStringInBodyText("Alice", "Wanda")
		
		set thisTitle to "Pages: Find & Change"
		set thisNotification to "Beginning 2nd replacement…"
		set thisSubtitle to "“Alice” to “Wanda” completed."
		my displayThisNotification(thisTitle, thisNotification, thisSubtitle)
		
		my replaceWordWithStringInBodyText("Alice's", "Wanda's")
		
		set thisNotification to "Replacement completed: “Alice's” to “Wanda's”"
		set thisSubtitle to ""
		my displayThisNotification(thisTitle, thisNotification, thisSubtitle)
	end if
end tell

on displayThisNotification(thisTitle, thisNotification, thisSubtitle)
	tell current application
		display notification thisNotification with title thisTitle subtitle thisSubtitle
	end tell
end displayThisNotification

on replaceWordWithStringInBodyText(searchWord, replacementString)
	tell application "Pages"
		activate
		tell the front document
			tell body text
				-- start at the end and go to the beginning
				repeat with i from the (count of paragraphs) to 1 by -1
					tell paragraph i
						repeat
							try
								if exists searchWord then
									set (last word where it is searchWord) to replacementString
								else
									exit repeat
								end if
							on error errorMessage
								exit repeat
							end try
						end repeat
					end tell
				end repeat
			end tell
		end tell
		return true
	end tell
end replaceWordWithStringInBodyText
