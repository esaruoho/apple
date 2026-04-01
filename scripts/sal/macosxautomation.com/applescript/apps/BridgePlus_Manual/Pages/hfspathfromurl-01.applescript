use scripting additions
use framework "Foundation"
use script "BridgePlus"
load framework

set aURL to Cocoaify (path to desktop)
-->	(NSURL) file:///Users/shane/Desktop/
set theResult to current application's SMSForder's HFSPathFromURL:aURL
theResult as text
-->	file "Macintosh HD:Users:shane:Desktop:"
