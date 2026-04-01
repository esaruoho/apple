use scripting additions
use framework "Foundation"
use script "BridgePlus"
load framework

set arrayOfDicts to {{firstLabel:1.1, secondLabel:2}, {firstLabel:3, secondLabel:4}, {firstLabel:5, secondLabel:6}}
set theKeys to {"firstLabel", "secondLabel"}
set theResult to current application's SMSForder's subarraysFrom:arrayOfDicts usingKeys:theKeys outKeys:(missing value) |error|:(missing value)
ASify from theResult
-->	{{1.1, 2}, {3, 4}, {5, 6}}
theResult as list -- 10.11 only
-->	{{1.1, 2}, {3, 4}, {5, 6}}
theResult as list -- 10.9 and 10.10
-->	{{1.100000023842, 2}, {3, 4}, {5, 6}}

set theKeys to {}
set {theResult, keysUsed} to current application's SMSForder's subarraysFrom:arrayOfDicts usingKeys:theKeys outKeys:(reference) |error|:(missing value)
ASify from theResult
-->	{{1.1, 2}, {3, 4}, {5, 6}}
theResult as list -- 10.11 only
-->	{{1.1, 2}, {3, 4}, {5, 6}}
theResult as list -- 10.9 and 10.10
-->	{{1.100000023842, 2}, {3, 4}, {5, 6}}
ASify from keysUsed
-->	{"firstLabel", "secondLabel"}
