tell application "Numbers"
	activate
	try
		set the chosenDocumentFile to ¬
			(choose file of type ¬
				{"com.apple.iwork.numbers.numbers", ¬
					"com.apple.iwork.numbers.sffnumbers", ¬
					"com.microsoft.excel.xls", ¬
					"org.openxmlformats.spreadsheetml.sheet"} ¬
					default location (path to documents folder) ¬
				with prompt "Choose the Numbers document or Excel workbook to open:")
		open the chosenDocumentFile
	on error errorMessage number errorNumber
		if errorNumber is not -128 then
			display alert errorNumber message errorMessage
		end if
	end try
end tell
