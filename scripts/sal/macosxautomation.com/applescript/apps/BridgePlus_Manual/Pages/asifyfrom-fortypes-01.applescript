use scripting additions
use framework "Foundation"
use script "BridgePlus"
load framework

set anItem to current application's NSDate's |date|()
set theResult to current application's SMSForder's ASifyFrom:anItem forTypes:"dates, files"
theResult as date
-->	date "Monday, 23 November 2015 at 12:16:19 PM"
