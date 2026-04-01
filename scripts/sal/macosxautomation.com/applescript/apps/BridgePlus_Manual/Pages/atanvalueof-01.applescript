use scripting additions
use framework "Foundation"
use script "BridgePlus"
load framework

set theResult to current application's SMSForder's atanValueOf:(45 / 180 * pi)
ASify from theResult
-->	0.665773750028
theResult as real
-->	0.665773750028
set theResult to current application's SMSForder's atanValueOf:{(30 / 180 * pi), (60 / 180 * pi), (90 / 180 * pi)}
ASify from theResult
-->	{0.482347907101, 0.80844879263, 1.003884821854}
theResult as list
-->	{0.482347907101, 0.80844879263, 1.003884821854}
