use scripting additions
use framework "Foundation"
use script "BridgePlus"
load framework

set listOrArray to {1.1, 2, 3, 4, 5, 6, 5, 4, 3}
set theResult to current application's SMSForder's sumMaxMinOf:listOrArray |error|:(missing value)
ASify from theResult
-->	{33.1, 6.0, 1.1}
theResult as list -- 10.11 only
-->	{33.1, 6.0, 1.1}
theResult as list -- 10.9 and 10.10
-->	{33.099998474121, 6.0, 1.100000023842}
