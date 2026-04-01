use scripting additions
use framework "Foundation"
use script "BridgePlus"
load framework

set aString to "This is a string. It has two sentences."
set theResult to current application's SMSForder's rangesOfLocalizedSentencesOfString:aString
ASify from theResult
-->	{{location:0, length:18}, {location:18, length:21}}
theResult as list
-->	{{location:0, length:18}, {location:18, length:21}}
