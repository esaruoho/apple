tell application id "com.apple.iWork.Keynote"
	activate
	tell the front document
		set the current slide to the first slide whose slide number is 2
	end tell
end tell
