use scripting additions
use framework "Foundation"
use script "BridgePlus"
load framework

set aString to "This is a string. And this also part of the STRING."
set theResult to current application's SMSForder's stringsOfString:"string" inString:aString options:(current application's NSCaseInsensitiveSearch)
ASify from theResult
-->	{"string", "STRING"}
theResult as list
-->	{"string", "STRING"}
set theLocale to current application's NSLocale's localeWithLocaleIdentifier:"tr"
set theResult to current application's SMSForder's stringsOfString:"string" inString:aString options:(current application's NSCaseInsensitiveSearch) locale:theLocale
ASify from theResult
-->	{"string"}
theResult as list
-->	{"string"}
