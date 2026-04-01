use scripting additions
use framework "Foundation"
use script "BridgePlus"
load framework

set aString to "This is a string. And this also part of the STRING."
set theResult to current application's SMSForder's rangesOfString:"string" inString:aString options:(current application's NSCaseInsensitiveSearch)
ASify from theResult
-->	{{location:10, length:6}, {location:44, length:6}}
theResult as list
-->	{{location:10, length:6}, {location:44, length:6}}

set theLocale to current application's NSLocale's localeWithLocaleIdentifier:"tr"
set theResult to current application's SMSForder's rangesOfString:"string" inString:aString options:(current application's NSCaseInsensitiveSearch) locale:theLocale
ASify from theResult
-->	{{location:10, length:6}}
theResult as list
-->	{{location:10, length:6}}
