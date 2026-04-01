tell application "Numbers"
	activate
	try
		tell the front document
			tell active sheet
				set thisTable to the first table whose class of selection range is range
				display dialog ¬
					"Save the entire table, or just the selection range, as an image?" buttons ¬
					{"Cancel", "Range", "Table"} default button 3 with icon 1
				set the userChoice to the button returned of the result
				if the userChoice is "Table" then
					tell thisTable
						-- store the selection range address
						set thisRange to the selection range
						-- select the entire table
						set the selection range to the cell range
						-- copy to selection to the clipboard
						tell application "System Events" to ¬
							keystroke "c" using command down
						-- restore the selection range to original state
						set the selection range to thisRange
						-- derive default image name
						set tableName to the name
						set the defaultName to (tableName & ".png")
					end tell
				else
					tell thisTable
						-- derive default image name
						set tableName to the name
						set the defaultName to (tableName & space & "Selection" & ".png")
					end tell
					-- copy to selection to the clipboard
					tell application "System Events" to ¬
						keystroke "c" using command down
				end if
			end tell
		end tell
		
		set the targetImageFile to (choose file name default name defaultName)
		set targetImageFileHFSPath to targetImageFile as string
		if targetImageFileHFSPath does not end with ".png" then
			set targetImageFileHFSPath to targetImageFileHFSPath & ".png"
		end if
		set the imageData to get the clipboard as «class PNGf»
		set the writeResult to my writeToFile(imageData, targetImageFileHFSPath, false)
		
		if writeResult is true then
			display dialog "The table image has been created." buttons ¬
				{"Send Image", "Show Image File", "OK"} default button 3 with icon 1
			set userChoice to the button returned of the result
			if userChoice is "Send Image" then
				tell application "Finder"
					open document file targetImageFileHFSPath ¬
						using application file id "com.apple.mail"
				end tell
			else if userChoice is "Show Image File" then
				tell application "Finder"
					activate
					reveal document file targetImageFileHFSPath
				end tell
			end if
		else
			error "There was a problem writing the image file."
		end if
	on error errorMessage number errorNumber
		if errorNumber is -1719 then
			set errorMessage to "Please select a table before running this script."
		end if
		if errorNumber is not -128 then
			display alert errorNumber message errorMessage
		end if
	end try
end tell

on writeToFile(thisData, targetFile, appendData)
	tell current application
		try
			set the targetFile to the targetFile as string
			set the openTargetFile to open for access file targetFile with write permission
			if appendData is false then set eof of the openTargetFile to 0
			write thisData to the openTargetFile starting at eof --as «class PNGf»
			close access the openTargetFile
			return true
		on error errorMessage
			try
				close access file targetFile
			end try
			log ("SCRIPT ERROR: " & errorMessage)
			return false
		end try
	end tell
end writeToFile
