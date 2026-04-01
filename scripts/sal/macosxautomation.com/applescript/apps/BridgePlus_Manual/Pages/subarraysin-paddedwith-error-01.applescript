use scripting additions
use framework "Foundation"
use script "BridgePlus"
load framework

set theLists to {{1.1, 2.1, 3, 4, 5}, {1, 2, 3}, {1, 2}}
set theResult to current application's SMSForder's subarraysIn:theLists paddedWith:0 |error|:(missing value)
ASify from theResult
-->	{{1.1, 2.1, 3, 4, 5}, {1, 2, 3, 0, 0}, {1, 2, 0, 0, 0}}
theResult as list -- 10.11 only
-->	{{1.1, 2.1, 3, 4, 5}, {1, 2, 3, 0, 0}, {1, 2, 0, 0, 0}}
theResult as list -- 10.9 and 10.10
-->	{{1.100000023842, 2.099999904633, 3, 4, 5}, {1, 2, 3, "x", "x"}, {1, 2, "x", "x", "x"}}

set {theResult, theError} to current application's SMSForder's subarraysIn:theLists paddedWith:"x" |error|:(reference)
if theResult = missing value then error (theError's localizedDescription() as text)
ASify from theResult
-->	{{1.1, 2.1, 3, 4, 5}, {1, 2, 3, "x", "x"}, {1, 2, "x", "x", "x"}}
theResult as list -- 10.11 only
-->	{{1.1, 2.1, 3, 4, 5}, {1, 2, 3, "x", "x"}, {1, 2, "x", "x", "x"}}
theResult as list -- 10.9 and 10.10
-->	{{1.100000023842, 2.099999904633, 3, 4, 5}, {1, 2, 3, "x", "x"}, {1, 2, "x", "x", "x"}}
