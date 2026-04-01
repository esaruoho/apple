tell application "Keynote"
	activate
	if not (exists document 1) then error number -128
	tell the front document
		repeat with i from 1 to the count of slides
			tell slide i
				set thisSlideNumber to the slide number
				set thisSlidesNotes to presenter notes
				set thisAudioFile to my renderAndEncode(thisSlidesNotes, thisSlideNumber)
				if thisAudioFile is not false then
					set thisAudioClip to ¬
						make new image with properties {file:thisAudioFile}
					my deleteFile(thisAudioFile)
				end if
				set transition properties to {automatic transition:false}
			end tell
		end repeat
	end tell
	start the front document from the first slide of the front document
end tell

on deleteFile(thisFileHFSAlias)
	set thisFilePOSIXPath to the POSIX path of thisFileHFSAlias
	do shell script "rm -f " & (quoted form of thisFilePOSIXPath)
end deleteFile

on renderAndEncode(thisSlidesNotes, thisSlideNumber)
	if thisSlidesNotes is "" then
		return false
	else
		-- get the path to the temp folder
		set the temporaryItemsFolder to the POSIX path of (path to temporary items)
		-- derive unique names for the audio files
		set thisTempName to (do shell script "uuidgen")
		set audioAIFFFileName to ¬
			"SLIDE-" & thisSlideNumber & "-" & thisTempName & ".aiff"
		set audioMPEGFileName to ¬
			"SLIDE-" & thisSlideNumber & "-" & thisTempName & ".m4a"
		-- construct the paths to the files to be created
		set targetAIFFFilePath to temporaryItemsFolder & audioAIFFFileName
		set targetMPEGFilePath to temporaryItemsFolder & audioMPEGFileName
		-- render text to AIFF audio file
		do shell script "say" & space & "-o" & space & ¬
			quoted form of targetAIFFFilePath & space & quoted form of thisSlidesNotes
		-- encode audio file to MPEG
		do shell script "afconvert -f 'm4af' -d 'aac ' -s 1 " & ¬
			(quoted form of targetAIFFFilePath) & space & (quoted form of targetMPEGFilePath)
		-- delete source audio file
		do shell script "rm -f " & (quoted form of targetAIFFFilePath)
		-- return reference to encoded audio file
		return (targetMPEGFilePath as POSIX file as alias)
	end if
end renderAndEncode
