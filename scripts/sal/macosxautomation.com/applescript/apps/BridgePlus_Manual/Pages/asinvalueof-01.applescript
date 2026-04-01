use scripting additions
use framework "Foundation"
use script "BridgePlus"
load framework

set theResult to current application's SMSForder's asinValueOf:(45 / 180 * pi)
ASify from theResult
-->	0.903339110767
theResult as real
-->	0.903339110767
set theResult to current application's SMSForder's asinValueOf:{(30 / 180 * pi), (60 / 180 * pi), (90 / 180 * pi)}
ASify from theResult
-->	{0.551069583099, missing value, missing value}
theResult as list
-->	{0.551069583099, missing value, missing value}
