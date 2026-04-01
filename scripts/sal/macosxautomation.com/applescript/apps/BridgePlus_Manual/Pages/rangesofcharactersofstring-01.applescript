use scripting additions
use framework "Foundation"
use script "BridgePlus"
load framework

set aString to "A 😀 string."
set theResult to current application's SMSForder's rangesOfCharactersOfString:aString
ASify from theResult
-->	{{location:0, length:1}, {location:1, length:1}, {location:2, length:2}, {location:4, length:1}, {location:5, length:1}, {location:6, length:1}, {location:7, length:1}, {location:8, length:1}, {location:9, length:1}, {location:10, length:1}, {location:11, length:1}}
theResult as list
-->	{{location:0, length:1}, {location:1, length:1}, {location:2, length:2}, {location:4, length:1}, {location:5, length:1}, {location:6, length:1}, {location:7, length:1}, {location:8, length:1}, {location:9, length:1}, {location:10, length:1}, {location:11, length:1}}
