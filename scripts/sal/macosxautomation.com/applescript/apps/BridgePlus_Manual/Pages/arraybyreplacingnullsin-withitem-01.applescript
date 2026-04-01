use scripting additions
use framework "Foundation"
use script "BridgePlus"
load framework

set listOrArray to {1.1, 2, missing value, 3, missing value, 4, 5}
set theResult to current application's SMSForder's arrayByReplacingNullsIn:listOrArray withItem:99
ASify from theResult
-->	{1.1, 2, 99, 3, 99, 4, 5}
theResult as list -- 10.11 only
-->	{1.1, 2, 99, 3, 99, 4, 5}
theResult as list -- 10.9 and 10.10
-->	{1.100000023842, 2, 99, 3, 99, 4, 5}
