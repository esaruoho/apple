use scripting additions
use framework "Foundation"
use script "BridgePlus"
load framework

set aURL to Cocoaify (choose file)
-->	(NSURL) file:///Users/shane/Desktop/Untitled%204.scptd/
set theResult to current application's SMSForder's HFSPathFromURL:aURL colonForPackages:true
theResult as text
-->	"Macintosh HD:Users:shane:Desktop:Untitled 4.scptd:"
set theResult to current application's SMSForder's HFSPathFromURL:aURL colonForPackages:false
theResult as text
-->	"Macintosh HD:Users:shane:Desktop:Untitled 4.scptd"
