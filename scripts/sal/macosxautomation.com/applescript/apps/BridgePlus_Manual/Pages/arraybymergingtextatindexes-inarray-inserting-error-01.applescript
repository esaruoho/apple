use scripting additions
use framework "Foundation"
use script "BridgePlus"
load framework

set listOrArray to {"apples", "oranges", "lemons", "peaches"}
set theIndexes to {1, 2}
set toInsert to " and "
set theResult to current application's SMSForder's arrayByMergingTextAtIndexes:theIndexes inArray:listOrArray inserting:toInsert |error|:(missing value)
ASify from theResult
-->	{"apples", "oranges and lemons", "peaches"}
theResult as list
-->	{"apples", "oranges and lemons", "peaches"}
set theIndexes to {3, 4}
set {theResult, theError} to current application's SMSForder's arrayByMergingTextAtIndexes:theIndexes inArray:listOrArray inserting:toInsert |error|:(reference)
if theResult = missing value then error (theError's localizedDescription() as text)
-->	error number -2700  At least one of the merge indexes is out of range or otherwise invalid.
