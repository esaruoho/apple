use scripting additions
use framework "Foundation"
use script "BridgePlus"
load framework

set theResult to current application's SMSForder's UTIForExtension:"jpg"
ASify from theResult
-->	"public.jpeg"
theResult as text
-->	"public.jpeg"
