use scripting additions
use framework "Foundation"
use script "BridgePlus"
load framework

set aString to "This is a string"
set theResult to current application's SMSForder's localizedWordsOfString:aString
ASify from theResult
-->	{"This", "is", "a", "string"}
theResult as list
-->	{"This", "is", "a", "string"}
