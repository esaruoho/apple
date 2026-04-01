use scripting additions
use framework "Foundation"
use script "BridgePlus"
load framework

set aString to "The cat sat in the cot"
set theResult to current application's SMSForder's findFirstMatch:"c[^a]t" inString:aString options:""
ASify from theResult
-->	"cot"
theResult as text -- only in 10.10 and later
-->	"cot"
set theResult to current application's SMSForder's findFirstMatch:"th." inString:aString options:""
ASify from theResult
-->	"the"
theResult as text
-->	"the"
set theResult to current application's SMSForder's findFirstMatch:"th." inString:aString options:"i"
ASify from theResult
-->	"The"
theResult as text
-->	"The"
