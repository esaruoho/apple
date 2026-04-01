use scripting additions
use framework "Foundation"
use script "BridgePlus"
load framework

set aString to "The cat sat in the cot"
set theResult to current application's SMSForder's findMatchRecords:"c.t" inString:aString options:""
ASify from theResult
-->	{{foundRange:{location:4, length:3}, captureGroup:0, foundString:"cat"}, {foundRange:{location:19, length:3}, captureGroup:0, foundString:"cot"}}
theResult as list -- only in 10.10 and later
-->	{{foundRange:{location:4, length:3}, captureGroup:0, foundString:"cat"}, {foundRange:{location:19, length:3}, captureGroup:0, foundString:"cot"}}

set theResult to current application's SMSForder's findMatchRecords:"th." inString:aString options:""
ASify from theResult
-->	{{foundRange:{location:15, length:3}, captureGroup:0, foundString:"the"}}
theResult as list
-->	{{foundRange:{location:15, length:3}, captureGroup:0, foundString:"the"}}

set theResult to current application's SMSForder's findMatchRecords:"th." inString:aString options:"i"
ASify from theResult
-->	{{foundRange:{location:0, length:3}, captureGroup:0, foundString:"The"}, {foundRange:{location:15, length:3}, captureGroup:0, foundString:"the"}}
theResult as list
-->	{{foundRange:{location:0, length:3}, captureGroup:0, foundString:"The"}, {foundRange:{location:15, length:3}, captureGroup:0, foundString:"the"}}
