use scripting additions
use framework "Foundation"
use script "BridgePlus"
load framework

set listOrArray to {{1.1, 2, 3, 4}, {5, 6, 7, 8}, {9, 10, 11, 12}}
set insertList to {"x", "y", "z"}
set theResult to current application's SMSForder's subarraysIn:listOrArray withItems:insertList insertedAtIndex:0 |error|:(missing value)
ASify from theResult
-->	{{"x", 1.1, 2, 3, 4}, {"y", 5, 6, 7, 8}, {"z", 9, 10, 11, 12}}
theResult as list -- 10.11 only
-->	{{"x", 1.1, 2, 3, 4}, {"y", 5, 6, 7, 8}, {"z", 9, 10, 11, 12}}
theResult as list -- 10.9 and 10.10
-->	{{"x", 1.100000023842, 2, 3, 4}, {"y", 5, 6, 7, 8}, {"z", 9, 10, 11, 12}}

set theResult to current application's SMSForder's subarraysIn:listOrArray withItems:insertList insertedAtIndex:4 |error|:(missing value)
ASify from theResult
-->	{{1.1, 2, 3, 4, "x"}, {5, 6, 7, 8, "y"}, {9, 10, 11, 12, "z"}}
theResult as list -- 10.11 only
-->	{{1.1, 2, 3, 4, "x"}, {5, 6, 7, 8, "y"}, {9, 10, 11, 12, "z"}}
theResult as list -- 10.9 and 10.10
-->	{{1.100000023842, 2, 3, 4, "x"}, {5, 6, 7, 8, "y"}, {9, 10, 11, 12, "z"}}

set {theResult, theError} to current application's SMSForder's subarraysIn:listOrArray withItems:insertList insertedAtIndex:5 |error|:(reference)
if theResult = missing value then error (theError's localizedDescription() as text)
-->	error number -2700  Invalid index.
