tell application "System Events"
	-- ACCOUNTS (Read-Only except picture of current user)
	get the properties of the current user
	--> returns: {class:user, picture path:file "Mac OS X:Library:User Pictures:Animals:Cat.tif", home directory:file "Mac OS X:Users:sal:", name:"sal", full name:"Sal Soghoian"}
	get the properties of every user
	--> returns: {{class:user, picture path:file "Mac OS X:Library:User Pictures:Flowers:Yellow Daisy.tif", home directory:file "Mac OS X:Users:sal:", name:"sal", full name:"Sal Soghoian"}}
	set the picture path of current user to alias "Mac OS X:Library:User Pictures:Flowers:Yellow Daisy.tif"
end tell
