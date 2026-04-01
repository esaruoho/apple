use scripting additions
use framework "Foundation"
use script "BridgePlus"
load framework

set aString to "The cat sat in the cot"
set theResult to current application's SMSForder's findMatches:"c.t" inString:aString options:""
ASify from theResult
-->	{"cat", "cot"}
theResult as list -- only in 10.10 and later
-->	{"cat", "cot"}

set theResult to current application's SMSForder's findMatches:"th." inString:aString options:""
ASify from theResult
-->	{"the"}
theResult as list
-->	{"the"}

set theResult to current application's SMSForder's findMatches:"th." inString:aString options:"i"
ASify from theResult
-->	{"The", "the"}
theResult as list
-->	{"The", "the"}
