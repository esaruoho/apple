use scripting additions
use framework "Foundation"
use script "BridgePlus"
load framework

set theResult to current application's SMSForder's tanhValueOf:(45 / 180 * pi)
ASify from theResult
-->	0.655794202633
theResult as real
-->	0.655794202633
set theResult to current application's SMSForder's tanhValueOf:{(30 / 180 * pi), (60 / 180 * pi), (90 / 180 * pi)}
ASify from theResult
-->	{0.480472778156, 0.780714435359, 0.917152335667}
theResult as list
-->	{0.480472778156, 0.780714435359, 0.917152335667}
