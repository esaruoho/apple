use scripting additions
use framework "Foundation"
use script "BridgePlus"
load framework

set theResult to current application's SMSForder's cosValueOf:(45 / 180 * pi)
ASify from theResult
-->	0.707106781187
theResult as real
-->	0.707106781187
set theResult to current application's SMSForder's cosValueOf:{(30 / 180 * pi), (60 / 180 * pi), (90 / 180 * pi)}
ASify from theResult
-->	{0.866025403784, 0.5, 6.12323399573677E-17}
theResult as list
-->	{0.866025403784, 0.5, 6.12323399573677E-17}
