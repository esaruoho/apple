use scripting additions
use framework "Foundation"
use script "BridgePlus"
load framework

set aString to "This is a string." & linefeed & "It is longer." & character id 133 & "It has three lines."
set theResult to current application's SMSForder's linesOfString:aString
ASify from theResult
-->	{"This is a string.", "It is longer.", "It has three lines."}
theResult as list
-->	{"This is a string.", "It is longer.", "It has three lines."}
