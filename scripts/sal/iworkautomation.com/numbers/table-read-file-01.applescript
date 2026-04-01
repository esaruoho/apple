on readTabSeparatedValuesFile(thisTSVFile)
	try
		set dataBlob to (every paragraph of (read thisTSVFile))
		set the tableData to {}
		set AppleScript's text item delimiters to tab
		repeat with i from 1 to the count of dataBlob
			set the end of the tableData to (every text item of (item i of dataBlob))
		end repeat
		set AppleScript's text item delimiters to ""
		return tableData
	on error errorMessage number errorNumber
		set AppleScript's text item delimiters to ""
		error errorMessage number errorNumber
	end try
end readTabSeparatedValuesFile
