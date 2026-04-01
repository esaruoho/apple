use scripting additions
use framework "Foundation"
use script "BridgePlus"
load framework

set aString to "This is a string. And this also part of the String."
set theResult to current application's SMSForder's stringsOfString:"string" inString:aString options:((current application's NSCaseInsensitiveSearch)   (current application's NSDiacriticInsensitiveSearch as integer))
ASify from theResult
-->	{"string", "String"}
theResult as list
-->	{"string", "String"}
