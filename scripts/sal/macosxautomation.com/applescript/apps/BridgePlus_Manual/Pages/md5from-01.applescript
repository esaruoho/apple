use scripting additions
use framework "Foundation"
use script "BridgePlus"
load framework

set aString to "0123456789"
set theResult to current application's SMSForder's MD5From:aString
ASify from theResult
-->	"781e5e245d69b566979b86e28d23f2c7"
theResult as text
-->	"781e5e245d69b566979b86e28d23f2c7"
