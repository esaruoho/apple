use scripting additions
use framework "Foundation"
use script "BridgePlus"
load framework

set anItem to current application's NSDate's |date|()
set theResult to current application's SMSForder's ASifyInListFrom:anItem forTypes:"dates, files"
item 1 of (theResult as list)
-->	date "Monday, 23 November 2015 at 12:17:05 PM"
