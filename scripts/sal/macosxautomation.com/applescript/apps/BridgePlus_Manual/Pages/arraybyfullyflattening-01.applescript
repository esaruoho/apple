use scripting additions
use framework "Foundation"
use script "BridgePlus"
load framework

set theLists to {{1.1, 2, 3}, {4, 5, 6}, {7, 8, 9}}
set theResult to current application's SMSForder's arrayByFullyFlattening:theLists
ASify from theResult
-->	{1.1, 2, 3, 4, 5, 6, 7, 8, 9}
theResult as list -- 10.11 only
-->	{1.1, 2, 3, 4, 5, 6, 7, 8, 9}
theResult as list -- 10.9 and 10.10
-->	{1.100000023842, 2, 3, 4, 5, 6, 7, 8, 9}

set theLists to {{1, 2, 3}, {4, {5, 6}, 7, 8, 9}}
set theResult to current application's SMSForder's arrayByFullyFlattening:theLists
ASify from theResult
-->	{1.1, 2, 3, 4, 5, 6, 7, 8, 9}
theResult as list -- 10.11 only
-->	{1.1, 2, 3, 4, 5, 6, 7, 8, 9}
theResult as list -- 10.9 and 10.10
-->	{1.100000023842, 2, 3, 4, 5, 6, 7, 8, 9}
