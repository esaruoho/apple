tell application "System Events"
	-- LOGIN ITEMS
	get the properties of every login item
	-- {{class:login item, path:"/Users/sal/Desktop/View Remote Screen.app", hidden:false, kind:"Application", name:"View Remote Screen"}}
	-- Adding a login item for the current user
	make new login item at end of login items with properties {path:"/Applications/Dictionary.app", hidden:false}
end tell
