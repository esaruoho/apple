use scripting additions
use framework "Foundation"
use script "BridgePlus"
load framework

set aString to "The price is $39.99"
set theResult to current application's SMSForder's findMatchRecords:"(\\d )\\.(\\d )" inString:aString options:"" captureGroups:{0, 1, 2}
ASify from theResult
-->	{{{foundRange:{location:14, length:5}, captureGroup:0, foundString:"39.99"}, {foundRange:{location:14, length:2}, captureGroup:1, foundString:"39"}, {foundRange:{location:17, length:2}, captureGroup:2, foundString:"99"}}}
theResult as list -- only in 10.10 and later
-->	{{{foundRange:{location:14, length:5}, captureGroup:0, foundString:"39.99"}, {foundRange:{location:14, length:2}, captureGroup:1, foundString:"39"}, {foundRange:{location:17, length:2}, captureGroup:2, foundString:"99"}}}

set aString to "The price is $39.99, normally $49.99"
set theResult to current application's SMSForder's findMatchRecords:"(\\d )\\.(\\d )" inString:aString options:"" captureGroups:{1, 2}
ASify from theResult
-->	{{{foundRange:{location:14, length:2}, captureGroup:1, foundString:"39"}, {foundRange:{location:17, length:2}, captureGroup:2, foundString:"99"}}, {{foundRange:{location:31, length:2}, captureGroup:1, foundString:"49"}, {foundRange:{location:34, length:2}, captureGroup:2, foundString:"99"}}}
theResult as list
-->	{{{foundRange:{location:14, length:2}, captureGroup:1, foundString:"39"}, {foundRange:{location:17, length:2}, captureGroup:2, foundString:"99"}}, {{foundRange:{location:31, length:2}, captureGroup:1, foundString:"49"}, {foundRange:{location:34, length:2}, captureGroup:2, foundString:"99"}}}
