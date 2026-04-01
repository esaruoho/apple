use scripting additions
use framework "Foundation"
use script "BridgePlus"
load framework

set aString to "A 😀 string."
set theResult to current application's SMSForder's rangesOfLocalizedWordsOfString:aString
ASify from theResult
-->	{{location:0, length:1}, {location:5, length:6}}
theResult as list
-->	{{location:0, length:1}, {location:5, length:6}}
