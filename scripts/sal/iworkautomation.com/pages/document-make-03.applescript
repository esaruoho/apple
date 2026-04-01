tell application "Pages"
	activate
	set templateNames to the name of every template
	repeat
		set thisTemplateName to ¬
			(choose from list templateNames with prompt ¬
				"Choose the template to use to create a blank layout document:")
		if thisTemplateName is false then error number -128
		set thisDocument to ¬
			make new document with properties ¬
				{document template:template (thisTemplateName as string)}
		tell thisDocument
			if document body is false then
				set locked of every iWork item to false
				delete every iWork item
				exit repeat
			else
				close thisDocument saving no
				display alert "WRONG TEMPLATE" message "The chosen template had an active document body." & return & return & "Choose a template that does not contain a document body text flow." buttons {"Cancel", "Try Again"} default button 2 cancel button "Cancel"
			end if
		end tell
	end repeat
end tell
