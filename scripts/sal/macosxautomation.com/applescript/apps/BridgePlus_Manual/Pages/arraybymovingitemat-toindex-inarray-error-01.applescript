use scripting additions
use framework "Foundation"
use script "BridgePlus"
load framework

set listOrArray to {1.1, 2, 3, 4, 5, 6}
set theResult to current application's SMSForder's arrayByMovingItemAt:0 toIndex:3 inArray:listOrArray |error|:(missing value)
ASify from theResult
-->	{2, 3, 4, 1.1, 5, 6}
theResult as list -- 10.11 only
-->	{2, 3, 4, 1.1, 5, 6}
theResult as list -- 10.9 and 10.10
-->	{2, 3, 4, 1.100000023842, 5, 6}

set theResult to current application's SMSForder's arrayByMovingItemAt:5 toIndex:0 inArray:listOrArray |error|:(missing value)
ASify from theResult
-->	{6, 1.1, 2, 3, 4, 5}
theResult as list -- 10.11 only
-->	{6, 1.1, 2, 3, 4, 5}
theResult as list -- 10.9 and 10.10
-->	{6, 1.100000023842, 2, 3, 4, 5}

set {theResult, theError} to current application's SMSForder's arrayByMovingItemAt:3 toIndex:7 inArray:listOrArray |error|:(reference)
if theResult = missing value then error (theError's localizedDescription() as text)
-->	error number -2700  Index is out of range.
