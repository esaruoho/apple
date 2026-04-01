property defaultTemplateName : "Blank"

tell application "Pages"
	activate
	set chosenFiles to ¬
		(choose file of type {"public.plain-text"} ¬
			with prompt "Choose the text files to import:" with multiple selections allowed)
	
	display dialog "Do you want to indicate the import order for the chosen files?" buttons ¬
		{"Cancel", "No", "Yes"} default button 3 with icon 1
	set performManualSort to the button returned of the result
	
	if performManualSort is "Yes" then
		set the fileCount to the count of chosenFiles
		set theseFileNames to {}
		repeat with i from 1 to the fileCount
			set thisFile to item i of chosenFiles
			set the end of theseFileNames to my fileNameFromAliasReference(thisFile)
		end repeat
		set the sourceList to chosenFiles
		set the sortedList to {}
		set theseDisplayNames to theseFileNames
		repeat with i from 1 to fileCount
			if i is fileCount then
				set chosenFileName to theseDisplayNames -- one item left
			else
				set thisFileIndexString to my addOrdinalSuffix(i)
				set chosenFileName to ¬
					(choose from list theseDisplayNames with prompt ¬
						"Double-click the " & thisFileIndexString & " file to import:")
			end if
			if chosenFileName is false then
				error number -128
			else
				set chosenFileName to chosenFileName as string
			end if
			repeat with z from 1 to count of theseFileNames
				if chosenFileName is item z of theseFileNames then
					set the end of the sortedList to item z of chosenFiles
					exit repeat
				end if
			end repeat
			set theseDisplayNames to my removeItemFromList(theseDisplayNames, chosenFileName)
		end repeat
		set theseFiles to sortedList
	else
		set theseFiles to chosenFiles
	end if
	
	set thisDocument to ¬
		make new document with properties ¬
			{document template:template defaultTemplateName}
	
	tell thisDocument
		if document body is false then
			display alert "INCOMPATIBLE TEMPLATE" message ¬
				"The created document does not have a document body text flow." & ¬
				return & return & "Choose a template that has a body text flow."
			error number -128
		end if
		
		repeat with i from 1 to the count of theseFiles
			if i is 1 then
				set body text to (read (item i of theseFiles))
			else
				make new section
				set body text of last section to (read (item i of theseFiles))
			end if
		end repeat
	end tell
	
	display notification "Import completed."
end tell

on fileNameFromAliasReference(thisFileAliasReference)
	set AppleScript's text item delimiters to ":"
	set thisFileName to the last text item of (thisFileAliasReference as string)
	set AppleScript's text item delimiters to ""
	return thisFileName
end fileNameFromAliasReference

on removeItemFromList(sourceList, targetItem)
	set newList to {}
	repeat with i from 1 to the count of sourceList
		set thisItem to item i of sourceList
		if thisItem is not targetItem then
			set the end of newList to (item i of sourceList)
		end if
	end repeat
	return newList
end removeItemFromList

on addOrdinalSuffix(thisInteger)
	set thisInteger to thisInteger as integer as string
	if thisInteger ends with "11" or ¬
		thisInteger ends with "12" or ¬
		thisInteger ends with "13" then
		set the listIndex to 1
	else
		set the listIndex to (thisInteger mod 10) + 1
	end if
	set the ordinalSuffix to item listIndex of ¬
		{"th", "st", "nd", "rd", "th", "th", "th", "th", "th", "th"}
	return (thisInteger & ordinalSuffix)
end addOrdinalSuffix
