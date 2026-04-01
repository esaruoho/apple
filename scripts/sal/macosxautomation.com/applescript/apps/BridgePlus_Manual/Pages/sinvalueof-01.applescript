use scripting additions
use framework "Foundation"
use script "BridgePlus"
load framework

set theResult to current application's SMSForder's sinValueOf:(45 / 180 * pi)
ASify from theResult
-->	0.707106781187
theResult as real
-->	0.707106781187
set theResult to current application's SMSForder's sinValueOf:{(30 / 180 * pi), (60 / 180 * pi), (90 / 180 * pi)}
ASify from theResult
-->	{0.5, 0.866025403784, 1.0}
theResult as list
-->	{0.5, 0.866025403784, 1.0}
