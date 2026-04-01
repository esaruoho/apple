use scripting additions
use framework "Foundation"
use script "BridgePlus"
load framework

set aString to "A 😀 string."
set theResult to current application's SMSForder's offsetOfLocation:2 inString:aString
-->	3
set theResult to current application's SMSForder's offsetOfLocation:4 inString:aString
-->	4
