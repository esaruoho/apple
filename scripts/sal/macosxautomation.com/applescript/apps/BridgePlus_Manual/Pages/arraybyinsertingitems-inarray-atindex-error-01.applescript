use scripting additions
use framework "Foundation"
use script "BridgePlus"
load framework

set listOrArray to {1.1, 2, 3, 4, 5, 6}
set insertList to {"x", "y", "z"}
set theResult to current application's SMSForder's arrayByInsertingItems:insertList inArray:listOrArray atIndex:0 |error|:(missing value)
ASify from theResult
-->	{"x", "y", "z", 1.1, 2, 3, 4, 5, 6}
theResult as list -- 10.11 only
-->	{"x", "y", "z", 1.1, 2, 3, 4, 5, 6}
theResult as list -- 10.9 and 10.10
-->	{"x", "y", "z", 1.100000023842, 2, 3, 4, 5, 6}

set theResult to current application's SMSForder's arrayByInsertingItems:insertList inArray:listOrArray atIndex:3 |error|:(missing value)
ASify from theResult
-->	{1.1, 2, 3, "x", "y", "z", 4, 5, 6}
theResult as list -- 10.11 only
-->	{1.1, 2, 3, "x", "y", "z", 4, 5, 6}
theResult as list -- 10.9 and 10.10
-->	{1.100000023842, 2, 3, "x", "y", "z", 4, 5, 6}

set {theResult, theError} to current application's SMSForder's arrayByInsertingItems:insertList inArray:listOrArray atIndex:7 |error|:(reference)
if theResult = missing value then error (theError's localizedDescription() as text)
-->	error number -2700  Index is out of range.
