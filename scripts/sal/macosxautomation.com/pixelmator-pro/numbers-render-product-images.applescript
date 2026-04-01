use AppleScript version "2.4" -- Yosemite (10.10) or later
use scripting additions

property headlineLayerName : "Headline"

try
	activate
	
	tell application id "com.apple.iWork.Numbers"
		if not (exists document 1) then error number -128
		tell front document
			tell active sheet
				if not (exists table 1) then error "The current spreadsheet does not include a table."
				tell table 1
					set languageNames to the formatted value of cells 2 thru -1 of column 1
					set the translatedHeadlines to the formatted value of cells 2 thru -1 of column 2
				end tell
			end tell
		end tell
		set destinationDirectory to (choose folder with prompt "Select the folder in which to place the exported images:")
	end tell
	
	tell application "Pixelmator Pro"
		activate
		if not (exists document 1) then error "No document is open in Pixelmator Pro."
		tell front document
			if not (exists text layer headlineLayerName) then
				error "The text layer “" & headlineLayerName & "” is not in the Pixelmator Pro document."
			end if
			
			-- GET/STORE DEFAULTS
			set documentName to the name of it
			if documentName ends with ".pxd" then
				set documentName to text 1 thru -5 of documentName
			end if
			tell text layer headlineLayerName
				set defaultFont to the font of it
				set defaultText to the text content of it
			end tell
			
			-- ITERATE THE SPREADSHEET ROWS
			set imageCount to the count of languageNames
			repeat with i from 1 to the imageCount
				
				-- Set the headline
				set thisLanguage to item i of languageNames
				set thisHeadline to item i of translatedHeadlines
				set the text content of text layer headlineLayerName to thisHeadline
				
				-- Adjust the font as needed
				if thisLanguage is "Simplified Chinese (CH)" then
					set font of text layer headlineLayerName to "PingFangSC-Light"
				else if thisLanguage is "Traditional Chinese (TA)" then
					set font of text layer headlineLayerName to "PingFangTC-Light"
				else if thisLanguage is "Japanese (J)" then
					set font of text layer headlineLayerName to "HiraginoSans-W1"
				else if thisLanguage is "Korean (KH)" then
					set font of text layer headlineLayerName to "AppleSDGothicNeo-Light"
				else if thisLanguage is "Thai (TH)" then
					set font of text layer headlineLayerName to "Thonburi-Light"
				else
					set font of text layer headlineLayerName to defaultFont
				end if
				
				-- Export the image
				set exportFilename to documentName & "-" & thisLanguage & ".jpg"
				set targetHFSPath to (destinationDirectory as string) & exportFilename
				export for web to file targetHFSPath as JPEG
				
				-- Show notification for export
				set notificationTitle to "Image Export (" & (i as string) & "/" & imageCount & ")"
				display notification exportFilename with title notificationTitle subtitle thisLanguage
			end repeat
			
			-- reset the headline layer
			set the text content of text layer headlineLayerName to defaultText
			set the font of text layer headlineLayerName to defaultFont
		end tell
	end tell
	
	-- Show the exported results
	tell application "Finder"
		activate
		open destinationDirectory
		select the first item of destinationDirectory
	end tell
on error errorMessage number errorNumber
	if errorNumber is not -128 then
		activate
		tell current application
			display alert "ERROR" message errorMessage buttons {"Cancel"} default button 1
		end tell
	end if
end try
