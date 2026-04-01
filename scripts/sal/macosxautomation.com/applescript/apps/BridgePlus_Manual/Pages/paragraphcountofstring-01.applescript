use scripting additions
use framework "Foundation"
use script "BridgePlus"
load framework

set aString to "This is a string." & linefeed & "It has two sentences."
set theResult to current application's SMSForder's paragraphCountOfString:aString
-->	2
