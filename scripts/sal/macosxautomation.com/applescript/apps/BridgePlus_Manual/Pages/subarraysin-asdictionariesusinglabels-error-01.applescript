use scripting additions
use framework "Foundation"
use script "BridgePlus"
load framework

set listOrArray to {{1.1, 2}, {3, 4}, {5, 6}}
set theLabels to {"firstLabel", "secondLabel"}
set theResult to current application's SMSForder's subarraysIn:listOrArray asDictionariesUsingLabels:theLabels |error|:(missing value)
ASify from theResult
-->	{{firstLabel:1.1, secondLabel:2}, {firstLabel:3, secondLabel:4}, {firstLabel:5, secondLabel:6}}
theResult as list -- 10.11 only
-->	{{firstLabel:1.1, secondLabel:2}, {firstLabel:3, secondLabel:4}, {firstLabel:5, secondLabel:6}}
theResult as list -- 10.9 and 10.10
-->	{{firstLabel:1.100000023842, secondLabel:2}, {firstLabel:3, secondLabel:4}, {firstLabel:5, secondLabel:6}}

set theLabels to {"firstLabel", "secondLabel", "thirdLabel"}
set {theResult, theError} to current application's SMSForder's subarraysIn:listOrArray asDictionariesUsingLabels:theLabels |error|:(reference)
if theResult = missing value then error (theError's localizedDescription() as text)
-->	error number -2700  Lists and label lists differ in length.
