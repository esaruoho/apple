tell application "System Events"
	tell CD and DVD preferences
		get the properties of video DVD -- Also: blank CD, blank DVD, music CD, picture CD, video CD
		-- > returns: {class:insertion preference, custom script:missing value, insertion action:open application, custom application:file "Mac OS X:System:Library:CoreServices:Front Row.app:"}
		
		-- OPEN APPLICATION		
		set properties of video DVD to {insertion action:open application, custom application:"/System/Lirabry/CoreServices/Front Row.app:"}
		
		-- RUN A SCRIPT
		set properties of picture CD to {insertion action:run a script, custom script:file "Mac OS X:Users:sal:Library:Scripts:Import Photo CD.scpt"}
	end tell
end tell
