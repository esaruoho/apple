-- Run this once after importing all Sal Demo Shortcuts.
-- Creates a "Sal Demo" folder in Shortcuts.app and moves all related Shortcuts in.
--
-- Usage:  osascript bin/organize-sal-shortcuts-into-folder.applescript

on run
	set salShortcuts to {¬
		"Sal Vacation Demo", ¬
		"Hey Sal", ¬
		"Take My Picture", ¬
		"Switch To Photos", ¬
		"Switch To Keynote", ¬
		"Switch To Maps", ¬
		"Switch To Numbers", ¬
		"Switch To Pages", ¬
		"Make A New Presentation", ¬
		"Add A Blank Slide", ¬
		"Duplicate Current Slide", ¬
		"Delete Current Slide", ¬
		"Go To First Slide", ¬
		"Go To Last Slide", ¬
		"Next Slide", ¬
		"Previous Slide", ¬
		"Apply Magic Move", ¬
		"Apply Dissolve", ¬
		"No Transition", ¬
		"Save Front Document", ¬
		"Insert Clipboard To Slide Title", ¬
		"Insert Clipboard To Slide Body", ¬
		"QR This", ¬
		"QR My Clipboard", ¬
		"Open The Documents Folder", ¬
		"Open The Pictures Folder", ¬
		"Open The Downloads Folder", ¬
		"Close All Finder Windows", ¬
		"Hide Other Applications", ¬
		"Display Wifi Network Name", ¬
		"Display Computer Name", ¬
		"New Mail Message", ¬
		"Play Presentation", ¬
		"Stop Presentation", ¬
		"Close Without Saving"}

	tell application "Shortcuts"
		-- Create folder if missing
		if not (exists folder "Sal Demo") then
			make new folder with properties {name:"Sal Demo"}
		end if

		set movedCount to 0
		set missingCount to 0
		repeat with sName in salShortcuts
			try
				set folder of shortcut (sName as text) to folder "Sal Demo"
				set movedCount to movedCount + 1
			on error
				set missingCount to missingCount + 1
			end try
		end repeat
	end tell

	display notification ("Moved " & movedCount & " Shortcuts to Sal Demo folder. " & missingCount & " not yet imported.") with title "Sal Demo Library"
	return "moved=" & movedCount & " missing=" & missingCount
end run
