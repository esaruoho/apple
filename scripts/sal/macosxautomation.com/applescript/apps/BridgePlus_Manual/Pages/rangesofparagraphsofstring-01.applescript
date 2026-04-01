use scripting additions
use framework "Foundation"
use script "BridgePlus"
load framework

set aString to "This is a string." & linefeed & "It has two paragraphs."
set theResult to current application's SMSForder's rangesOfParagraphsOfString:aString
ASify from theResult
-->	{{location:0, length:17}, {location:18, length:22}}
theResult as list
-->	{{location:0, length:17}, {location:18, length:22}}
