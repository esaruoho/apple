use scripting additions
use framework "Foundation"
use script "BridgePlus"
load framework

set aString to "This is a string"
set theResult to current application's SMSForder's charactersOfString:aString
ASify from theResult
-->	{"T", "h", "i", "s", " ", "i", "s", " ", "a", " ", "s", "t", "r", "i", "n", "g"}
theResult as list
-->	{"T", "h", "i", "s", " ", "i", "s", " ", "a", " ", "s", "t", "r", "i", "n", "g"}
