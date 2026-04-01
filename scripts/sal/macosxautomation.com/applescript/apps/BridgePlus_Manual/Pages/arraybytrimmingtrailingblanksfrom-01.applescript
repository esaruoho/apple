use scripting additions
use framework "Foundation"
use script "BridgePlus"
load framework

set listOrArray to {1.1, 2, "", 3, {}, 4, {"", ""}, 5, missing value, 6, {missing value, ""}, {}}
set theResult to current application's SMSForder's arrayByTrimmingTrailingBlanksFrom:listOrArray
ASify from theResult
-->	{1.1, 2, "", 3, {}, 4, {"", ""}, 5, missing value, 6}
theResult as list -- 10.11 only
-->	{1.1, 2, "", 3, {}, 4, {"", ""}, 5, missing value, 6}
theResult as list -- 10.9 and 10.10
-->	{1.100000023842, 2, "", 3, {}, 4, {"", ""}, 5, missing value, 6}
