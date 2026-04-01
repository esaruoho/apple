use scripting additions
use framework "Foundation"
use script "BridgePlus"
load framework

set theLists to {{1.1, 2, 3}, {4, 5, 6}, {7, 8, 9}}
set theResult to current application's SMSForder's colsToRowsIn:theLists |error|:(missing value)
ASify from theResult
-->	{{1.1, 4, 7}, {2, 5, 8}, {3, 6, 9}}
theResult as list -- 10.11 only
-->	{{1.1, 4, 7}, {2, 5, 8}, {3, 6, 9}}
theResult as list -- 10.9 and 10.10
-->	{{1.100000023842, 4, 7}, {2, 5, 8}, {3, 6, 9}}

set theLists to {{1, 2, 3}, {4, 5}, {7, 8, 9}}
set {theResult, theError} to current application's SMSForder's colsToRowsIn:theLists |error|:(reference)
if theResult = missing value then error (theError's localizedDescription() as text)
-->	error number -2700  Can't perform cols to rows when lists have differing item counts.
