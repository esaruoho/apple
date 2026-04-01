tell application "Keynote"
	activate
	if playing is true then tell the front document to stop
	if not (exists document 1) then error number -128
	
	tell front document
		set thesePresenterNotes to ¬
			the presenter notes of every slide whose skipped is false
	end tell
end tell

tell application "OmniOutliner"
	activate
	set thisDocument to make new document
	tell thisDocument
		repeat with i from 1 to the count of thesePresenterNotes
			set thisPresenterNote to item i of thesePresenterNotes
			make new row with properties {topic:thisPresenterNote}
		end repeat
	end tell
end tell
