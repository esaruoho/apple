use scripting additions
use framework "Foundation"
use script "BridgePlus"
load framework

set theResult to current application's SMSForder's sinhValueOf:(45 / 180 * pi)
ASify from theResult
-->	0.868670961486
theResult as real
-->	0.868670961486
set theResult to current application's SMSForder's sinhValueOf:{(30 / 180 * pi), (60 / 180 * pi), (90 / 180 * pi)}
ASify from theResult
-->	{0.547853473888, 1.249367050524, 2.301298902307}
theResult as list
-->	{0.547853473888, 1.249367050524, 2.301298902307}
