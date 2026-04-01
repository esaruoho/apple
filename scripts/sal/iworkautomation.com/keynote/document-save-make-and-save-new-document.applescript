-- Create a new document and save it into the Documents folder

-- generate the default file name
set todaysDate to (current date)
set the nameToUse to ¬
	("Monthly Report - " & (month of todaysDate) as string) & ¬
	space & (year of todaysDate) as string
--> "Monthly Report - December 2014"

-- make sure the file name is not in use
set the destinationFolderHFSPath to ¬
	(path to the documents folder) as string
repeat with i from 0 to 100000
	if i is 0 then
		set incrementText to ""
	else
		set incrementText to "-" & (i as string)
	end if
	set thisFileName to nameToUse & incrementText & ".key"
	set thisFilePath to destinationFolderHFSPath & thisFileName
	tell application "Finder"
		if not (exists document file thisFilePath) then exit repeat
	end tell
end repeat

tell application "Keynote"
	activate
	-- create a new document and store its reference in a variable
	set thisDocument to make new document
	-- save the document
	save thisDocument in file thisFilePath
end tell
