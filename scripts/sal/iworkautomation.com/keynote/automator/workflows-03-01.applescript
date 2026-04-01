tell application "Keynote"
	set thisName to the name of the front document
end tell
if thisName ends with ".key" then set thisName to text 1 thru -5 of thisName
return ("Presenter Notes from " & thisName)
