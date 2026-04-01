use scripting additions
use framework "Foundation"
use script "BridgePlus"
load framework

set aString to "café à Paris"
set theResult to current application's SMSForder's encodedHexFrom:aString
ASify from theResult
-->	"caf&#xE9; &#xE0; Paris"
theResult as text
-->	"caf&#xE9; &#xE0; Paris"
