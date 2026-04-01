use scripting additions
use framework "Foundation"
use script "BridgePlus"
load framework

set aString to "This is a string." & character id 133 & "It has two lines."
set theResult to current application's SMSForder's lineCountOfString:aString
-->	2
