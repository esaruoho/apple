tell application "Keynote"
	activate
	if not (exists document 1) then error number -128
	tell the front document
		set thisDocumentName to the name of it
		set the combinedPresenterNotes to ¬
			"PRESENTER NOTES FOR: “" & thisDocumentName & "”" & return
		repeat with i from 1 to the count of slides
			tell slide i
				if skipped is false then
					set the combinedPresenterNotes to ¬
						combinedPresenterNotes & return & return & ¬
						"SLIDE " & (i as string) & " • " & presenter notes of it
				end if
			end tell
		end repeat
	end tell
end tell

tell application "Pages"
	activate
	set thisDocument to ¬
		make new document with properties {document template:template "Blank"}
	tell thisDocument
		set body text to combinedPresenterNotes
	end tell
end tell
