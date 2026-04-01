use scripting additions
use framework "Foundation"
use script "BridgePlus"
load framework

set aString to "   Of time  and     space   "
set theResult to current application's SMSForder's cleanSpacedFrom:aString
ASify from theResult
-->	"Of time and space"
theResult as text
-->	"Of time and space"
