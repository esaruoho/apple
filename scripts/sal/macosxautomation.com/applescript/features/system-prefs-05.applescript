tell application "System Events"
	tell appearance preferences
		get properties
		--> returns: {scroll arrow placement:together, font smoothing limit:4, recent applications limit:10, scroll bar action:jump to next page, double click minimizes:true, recent servers limit:10, appearance:blue, recent documents limit:10, highlight color:{46516, 54741, 65535}, class:appearance preferences object, smooth scrolling:false, font smoothing style:automatic}
		set properties to {scroll arrow placement:together at top and bottom, font smoothing limit:4, recent applications limit:10, scroll bar action:jump to here, double click minimizes:true, recent servers limit:20, appearance:blue, recent documents limit:20, highlight color:{0, 0, 32000}, smooth scrolling:true, font smoothing style:light}
	end tell
end tell
