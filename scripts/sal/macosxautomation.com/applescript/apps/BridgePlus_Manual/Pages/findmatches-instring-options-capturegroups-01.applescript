use scripting additions
use framework "Foundation"
use script "BridgePlus"
load framework

set aString to "The price is $39.99"
set theResult to current application's SMSForder's findMatches:"(\\d )\\.(\\d )" inString:aString options:"" captureGroups:{0, 1, 2}
ASify from theResult
-->	{{"39.33", "39", "33"}}
theResult as list
-->	{{"39.33", "39", "33"}}
set aString to "The price is $39.99, normally $49.99"

set theResult to current application's SMSForder's findMatches:"(\\d )\\.(\\d )" inString:aString options:"" captureGroups:{1, 2}
ASify from theResult
-->	{{"39", "99"}, {"49", "99"}}
theResult as list
-->	{{"39", "99"}, {"49", "99"}}
