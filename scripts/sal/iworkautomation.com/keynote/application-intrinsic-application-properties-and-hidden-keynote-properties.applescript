-- INTRINSIC APPLICATION PROPERTIES FOR ALL APPLICATIONS
get the id of application "Keynote"
--> "com.apple.iWork.Keynote"
get running of application "Keynote"
--> true
get the version of application "Keynote"
--> "6.2"

-- HIDDEN KEYNOTE APPLICATION PROPERTIES
tell application "Keynote"
	get properties
	{frozen:true, class:application, playing:false, version:"6.2", slide switcher visible:false, name:"Keynote", frontmost:false}
end tell
