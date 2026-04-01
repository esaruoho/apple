use scripting additions
use framework "Foundation"
use script "BridgePlus"
load framework

set aString to "This is a string." & linefeed & "It has two paragraphs."
set theResult to current application's SMSForder's paragraphsOfString:aString
ASify from theResult
-->	{"This is a string.", "It has two paragraphs."}
theResult as list
-->	{"This is a string.", "It has two paragraphs."}
