use scripting additions
use framework "Foundation"
use script "BridgePlus"
load framework

set theResult to current application's SMSForder's CocoaifyFrom:{"Some string", current date} forTypes:"dates, files"
-->	(NSArray) {"Some string", (NSDate) 2015-11-23 01:08:38  0000}
