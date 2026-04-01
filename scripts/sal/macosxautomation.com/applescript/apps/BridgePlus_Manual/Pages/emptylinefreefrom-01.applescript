use scripting additions
use framework "Foundation"
use script "BridgePlus"
load framework

set aString to "One

Two
Three
"
set theResult to current application's SMSForder's emptyLineFreeFrom:aString
ASify from theResult
-->	"One
--     Two
--     Three"
theResult as text
-->	"One
--     Two
--     Three"
