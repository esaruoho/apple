use scripting additions
use framework "Foundation"
use script "BridgePlus"
load framework

set listOrArray to {{5, 2.1, 7}, {1, 2.2, 3}, {4, 2.3, 6}, {7, 3, 9}, {10, 1, 12}}
set theIndexes to {1, 0}
set theOrders to {true, true}
set sortTypes to {"compare:", "compare:"}
set theResult to current application's SMSForder's subarraysIn:listOrArray sortedByIndexes:theIndexes ascending:theOrders sortTypes:sortTypes sortKeys:{"integerValue"} |error|:(missing value)
ASify from theResult
-->	{{10, 1, 12}, {1, 2.2, 3}, {4, 2.3, 6}, {5, 2.1, 7}, {7, 3, 9}}
theResult as list -- 10.11 only
-->	{{10, 1, 12}, {1, 2.2, 3}, {4, 2.3, 6}, {5, 2.1, 7}, {7, 3, 9}}
theResult as list -- 10.9 and 10.10
-->	{{10, 1, 12}, {1, 2.200000047684, 3}, {4, 2.299999952316, 6}, {5, 2.099999904633, 7}, {7, 3, 9}}

set theIndexes to {1, 3}
set {theResult, theError} to current application's SMSForder's subarraysIn:listOrArray sortedByIndexes:theIndexes ascending:theOrders sortTypes:sortTypes sortKeys:{} |error|:(reference)
if theResult = missing value then error (theError's localizedDescription() as text)
-->	error number -2700  Sublist has fewer items than in sort indexes list.
