use scripting additions
use framework "Foundation"
use script "BridgePlus"
load framework

set aString to "It's \"one\" two 'three'"
set theResult to current application's SMSForder's smartQuotedFrom:aString
ASify from theResult
-->	"It’s “one” two ‘three’"
theResult as text
-->	"It’s “one” two ‘three’"
