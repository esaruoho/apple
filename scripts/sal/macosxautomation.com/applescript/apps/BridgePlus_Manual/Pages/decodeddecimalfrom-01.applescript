use scripting additions
use framework "Foundation"
use script "BridgePlus"
load framework

set aString to "caf&#233; &#224; Paris"
set theResult to current application's SMSForder's decodedDecimalFrom:aString
ASify from theResult
-->	"café à Paris"
theResult as text
-->	"café à Paris"
