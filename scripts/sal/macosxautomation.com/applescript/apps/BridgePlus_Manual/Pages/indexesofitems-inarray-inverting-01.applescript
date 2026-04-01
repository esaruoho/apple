use scripting additions
use framework "Foundation"
use script "BridgePlus"
load framework

set listOrArray to {1, 2, 3, 2, 4, 2, 5, 3}
set theItem to {2, 4}
set theResult to current application's SMSForder's indexesOfItems:theItem inArray:listOrArray inverting:false
ASify from theResult
-->	{1, 3, 4, 5}
theResult as list
-->	{1, 3, 4, 5}
set theResult to current application's SMSForder's indexesOfItems:theItem inArray:listOrArray inverting:true
ASify from theResult
-->	{0, 2, 6, 7}
theResult as list
-->	{0, 2, 6, 7}
