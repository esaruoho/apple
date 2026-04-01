use scripting additions
use framework "Foundation"
use script "BridgePlus"
load framework

set aString to "A 😀 string."
set theResult to current application's SMSForder's offsetsOfRange:{location:0, |length|:6} inString:aString
ASify from theResult
-->	{1, 5}
theResult as list
-->	{1, 5}
