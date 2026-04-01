use scripting additions
use framework "Foundation"
use script "BridgePlus"
load framework

set aString to "This is a string." & linefeed & "It is longer." & character id 133 & "It has three lines."
set theResult to current application's SMSForder's rangesOfLinesOfString:aString
ASify from theResult
-->	{{location:0, length:17}, {location:18, length:13}, {location:32, length:19}}
theResult as list
-->	{{location:0, length:17}, {location:18, length:13}, {location:32, length:19}}
