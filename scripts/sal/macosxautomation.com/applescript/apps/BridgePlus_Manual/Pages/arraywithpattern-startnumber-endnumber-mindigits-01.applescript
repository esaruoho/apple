use scripting additions
use framework "Foundation"
use script "BridgePlus"
load framework

set patternString to "File number %@"
set theResult to current application's SMSForder's arrayWithPattern:patternString startNumber:10 endNumber:20 minDigits:4
ASify from theResult
-->	{"File number 0010", "File number 0011", "File number 0012", "File number 0013", "File number 0014", "File number 0015", "File number 0016", "File number 0017", "File number 0018", "File number 0019", "File number 0020"}
theResult as list
-->	{"File number 0010", "File number 0011", "File number 0012", "File number 0013", "File number 0014", "File number 0015", "File number 0016", "File number 0017", "File number 0018", "File number 0019", "File number 0020"}
