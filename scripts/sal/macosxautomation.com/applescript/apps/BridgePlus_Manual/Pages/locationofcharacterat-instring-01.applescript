use scripting additions
use framework "Foundation"
use script "BridgePlus"
load framework

set aString to "A 😀 string."
set theResult to current application's SMSForder's locationOfCharacterAt:3 inString:aString
-->	2
set theResult to current application's SMSForder's locationOfCharacterAt:4 inString:aString
-->	4
