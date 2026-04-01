use scripting additions
use framework "Foundation"
use script "BridgePlus"
load framework

set aString to "café à Paris"
set theResult to current application's SMSForder's encodedDecimalFrom:aString
ASify from theResult
-->	"caf&#233; &#224; Paris"
theResult as text
-->	"caf&#233; &#224; Paris"
