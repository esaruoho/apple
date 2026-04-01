tell application "Pages"
	activate
	try
		set the chosenDocumentFile to ¬
			(choose file of type ¬
				{"com.apple.iwork.pages.pages", ¬
					"com.microsoft.word.doc", ¬
					"org.openxmlformats.wordprocessingml.document"} ¬
					default location (path to documents folder) ¬
				with prompt "Choose the Pages or Microsoft Word document to open:")
		open the chosenDocumentFile
	on error errorMessage number errorNumber
		if errorNumber is not -128 then
			display alert errorNumber message errorMessage
		end if
	end try
end tell
