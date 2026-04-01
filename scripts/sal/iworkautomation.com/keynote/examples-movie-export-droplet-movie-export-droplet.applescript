property destinationFolder : (path to movies folder)

on run
	-- TRIGGERED WHEN USER LAUNCHES DROPLET. PROMPT FOR PRESENTATION FILE(S):
	set theseItems to ¬
		(choose file of type "com.apple.iwork.keynote.key" with prompt ¬
			"Pick the Keynote presentation(s) to export to movie:" with multiple selections allowed)
	open theseItems
end run

on open theseItems
	-- TRIGGERED WHEN USER DRAGS ITEMS ONTO THE DROPLET
	display dialog "This droplet will export dragged-on Keynote presentation files as movies to the Movies folder." & return & return & "The movies will be encoded to MPEG format using H.264 compression." with icon 1
	set the filesToProcess to {}
	-- filter the dragged-on items for Keynote presentation files
	repeat with i from 1 to the count of theseItems
		set thisItem to item i of theseItems
		if my checkForIdentifier(thisItem, "com.apple.iwork.keynote.key") is true then
			set the end of the filesToProcess to thisItem
		end if
	end repeat
	if filesToProcess is {} then
		activate
		display alert "INCOMPATIBLE ITEMS" message "None of the items were Keynote presentations."
	else
		-- process the presentations
		my exportPresentationsToMovies(filesToProcess)
	end if
end open

on checkForIdentifier(thisItem, thisIdentifier)
	try
		-- uses Spotlight to check for specified item type
		set the queryResult to ¬
			(do shell script "mdls -name kMDItemContentType " & ¬
				quoted form of the POSIX path of thisItem)
		if queryResult contains "(null)" then
			return false
		else
			set x to the length of "kMDItemContentType = \""
			set the indentifierString to text (x + 1) thru -2 of queryResult
			if the indentifierString is thisIdentifier then
				return true
			end if
		end if
	on error
		return false
	end try
end checkForIdentifier

on exportPresentationsToMovies(thesePresentations)
	try
		repeat with i from 1 to the count of thesePresentations
			set thisPresentation to item i of thesePresentations
			tell application "Keynote"
				activate
				if playing is true then tell front document to stop
				open thisPresentation
				set the documentName to name of the front document
				copy my deriveFileNameForNewFileInFolder(documentName, destinationFolder) to ¬
					{targetName, targetPOSIXpath}
				set destinationFile to (targetPOSIXpath as POSIX file)
				with timeout of 1200 seconds -- 20 minutes
					export front document to destinationFile ¬
						as QuickTime movie with properties {movie format:large}
				end timeout
				close front document saving no
			end tell
			display notification documentName with title "Keynote Movie Export"
		end repeat
	on error errorMessage
		activate
		display alert "EXPORT ERROR" message errorMessage
		error number -128
	end try
end exportPresentationsToMovies

on deriveFileNameForNewFileInFolder(sourceItemBaseName, targetFolderHFSAlias)
	-- UNIX routine that derives a none-conflicting file name
	set targetFolderPOSIXPath to (POSIX path of targetFolderHFSAlias)
	set incrementSeparator to "-"
	set targetExtension to "m4v"
	set extensionSeparator to "."
	
	set targetName to sourceItemBaseName & extensionSeparator & targetExtension
	set targetItemPOSIXPath to targetFolderPOSIXPath & targetName
	set the fileExistenceStatus to ¬
		(do shell script "[ -a " & (quoted form of targetItemPOSIXPath) & ¬
			" ] && echo 'true' || echo 'false'") as boolean
	if fileExistenceStatus is true then
		set the nameIncrement to 1
		repeat
			-- create a new target path with the target item name incremented
			set the newName to ¬
				(the sourceItemBaseName & incrementSeparator & ¬
					(nameIncrement as Unicode text) & ¬
					extensionSeparator & targetExtension) as Unicode text
			set targetItemPOSIXPath to targetFolderPOSIXPath & newName
			set the fileExistenceStatus to ¬
				(do shell script "[ -a " & (quoted form of targetItemPOSIXPath) & ¬
					" ] && echo 'true' || echo 'false'") as boolean
			if fileExistenceStatus is true then
				set the nameIncrement to the nameIncrement + 1
			else
				set the targetPOSIXpath to (targetFolderPOSIXPath & newName)
				return {newName, targetPOSIXpath}
			end if
		end repeat
	else
		set the targetPOSIXpath to (targetFolderPOSIXPath & targetName)
		return {targetName, targetPOSIXpath}
	end if
end deriveFileNameForNewFileInFolder
