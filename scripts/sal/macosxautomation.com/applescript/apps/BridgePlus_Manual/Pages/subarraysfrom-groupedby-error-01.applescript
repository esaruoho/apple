use scripting additions
use framework "Foundation"
use script "BridgePlus"
load framework

set theList to {1.1, 2, 3, 4, 5, 6, 7, 8, 9}
set theResult to current application's SMSForder's subarraysFrom:theList groupedBy:2 |error|:(missing value)
ASify from theResult
-->	{{1.1, 2}, {3, 4}, {5, 6}, {7, 8}, {9}}
theResult as list -- 10.11 only
-->	{{1.1, 2}, {3, 4}, {5, 6}, {7, 8}, {9}}
theResult as list -- 10.9 and 10.10
-->	{{1.100000023842, 2}, {3, 4}, {5, 6}, {7, 8}, {9}}

set {theResult, theError} to current application's SMSForder's subarraysFrom:theList groupedBy:4 |error|:(reference)
if theResult = missing value then error (theError's localizedDescription() as text)
ASify from theResult
-->	{{1.1, 2, 3, 4}, {5, 6, 7, 8}, {9}}
theResult as list -- 10.11 only
-->	{{1.1, 2, 3, 4}, {5, 6, 7, 8}, {9}}
theResult as list -- 10.9 and 10.10
-->	{{1.100000023842, 2, 3, 4}, {5, 6, 7, 8}, {9}}
