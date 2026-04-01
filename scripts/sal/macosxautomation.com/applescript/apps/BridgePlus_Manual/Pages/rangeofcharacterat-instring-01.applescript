use scripting additions
use framework "Foundation"
use script "BridgePlus"
load framework

set aString to "A 😀 string."
set theResult to current application's SMSForder's rangeOfCharacterAt:3 inString:aString
-->	{location:2, length:2}
set theResult to current application's SMSForder's rangeOfCharacterAt:4 inString:aString
-->	{location:4, length:1}
