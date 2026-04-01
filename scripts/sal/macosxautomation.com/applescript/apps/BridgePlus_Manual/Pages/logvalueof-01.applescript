use scripting additions
use framework "Foundation"
use script "BridgePlus"
load framework

set theResult to current application's SMSForder's logValueOf:2.71828182846
ASify from theResult
-->	1.0
theResult as real
-->	1.0
set theResult to current application's SMSForder's logValueOf:{1, 2, 10, 100}
ASify from theResult
-->	{0.0, 0.69314718056, 2.302585092994, 4.605170185988}
theResult as list
-->	{0.0, 0.69314718056, 2.302585092994, 4.605170185988}
