use scripting additions
use framework "Foundation"
use script "BridgePlus"
load framework

set theIndexSet to current application's NSIndexSet's indexSetWithIndexesInRange:{location:3, |length|:10}
set theResult to current application's SMSForder's arrayWithIndexSet:theIndexSet
ASify from theResult
-->	{3, 4, 5, 6, 7, 8, 9, 10, 11, 12}
theResult as list
-->	{3, 4, 5, 6, 7, 8, 9, 10, 11, 12}
