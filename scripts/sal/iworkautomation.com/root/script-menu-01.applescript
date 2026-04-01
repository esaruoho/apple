set displayNameOfNumbers to the name of application id "com.apple.iwork.numbers"
set displayNameOfPages to the name of application id "com.apple.iwork.pages"
set displayNameOfKeynote to the name of application id "com.apple.iwork.keynote"
set displayNameOfContacts to the name of application id "com.apple.addressbook"

set the applicationsList to {displayNameOfNumbers, displayNameOfPages, displayNameOfKeynote, displayNameOfContacts}

tell application id "com.apple.AppleScriptUtility"
	if Script menu enabled is false then
		set Script menu enabled to true
		set application scripts position to top
		set show Computer scripts to false
	end if
end tell
set the UserScriptsFolder to (path to scripts folder from user domain)
tell application "Finder"
	activate
	if not (exists folder "Applications" of UserScriptsFolder) then
		make new folder at UserScriptsFolder with properties {name:"Applications"}
	end if
	open folder "Applications" of UserScriptsFolder
	tell folder UserScriptsFolder
		tell folder "Applications"
			repeat with i from 1 to the count of the applicationsList
				set thisApplicationName to (item i of the applicationsList) as string
				if not (exists folder thisApplicationName) then
					make new folder at it with properties {name:thisApplicationName}
				end if
			end repeat
		end tell
	end tell
end tell
