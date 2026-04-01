use scripting additions
use framework "Foundation"
use script "BridgePlus"
load framework

set anInteger to 10
set arrayOfIntegers to {1, 2, 3, 4, 5}
set theResult to current application's SMSForder's arrayByAddingInteger:anInteger inArray:arrayOfIntegers
ASify from theResult
-->	{11, 12, 13, 14, 15}
theResult as list
-->	{11, 12, 13, 14, 15}

set anInteger to -10
set theResult to current application's SMSForder's arrayByAddingInteger:anInteger inArray:arrayOfIntegers
ASify from theResult
-->	{-9, -8, -7, -6, -5}
theResult as list
-->	{-9, -8, -7, -6, -5}
