use scripting additions
use framework "Foundation"
use script "BridgePlus"
load framework

set theResult to current application's SMSForder's URLsFrom:{path to desktop, "/Applications", "~/Documents"}
-->	(NSArray) {(NSURL) file:///Users/shane/Desktop/, (NSURL) file:///Applications/, (NSURL) file:///Users/shane/Documents/}
