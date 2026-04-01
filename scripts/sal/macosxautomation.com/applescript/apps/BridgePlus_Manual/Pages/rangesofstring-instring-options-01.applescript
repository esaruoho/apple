use scripting additions
use framework "Foundation"
use script "BridgePlus"
load framework

set aString to "This is a string. And this also part of the String."
set theResult to current application's SMSForder's rangesOfString:"string" inString:aString options:((current application's NSCaseInsensitiveSearch)   (current application's NSDiacriticInsensitiveSearch as integer))
ASify from theResult
-->	{{location:10, length:6}, {location:44, length:6}}
theResult as list
-->	{{location:10, length:6}, {location:44, length:6}}
