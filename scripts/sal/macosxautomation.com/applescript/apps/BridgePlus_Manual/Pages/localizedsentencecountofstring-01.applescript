use scripting additions
use framework "Foundation"
use script "BridgePlus"
load framework

set aString to "This is a string. It has two sentences."
set theResult to current application's SMSForder's localizedSentenceCountOfString:aString
-->	2
