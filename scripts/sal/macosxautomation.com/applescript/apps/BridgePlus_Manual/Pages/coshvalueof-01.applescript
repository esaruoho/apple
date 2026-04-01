use scripting additions
use framework "Foundation"
use script "BridgePlus"
load framework

set theResult to current application's SMSForder's coshValueOf:(45 / 180 * pi)
ASify from theResult
-->	1.324609089252
theResult as real
-->	1.324609089252
set theResult to current application's SMSForder's coshValueOf:{(30 / 180 * pi), (60 / 180 * pi), (90 / 180 * pi)}
ASify from theResult
-->	{1.140238321076, 1.600286857702, 2.509178478658}
theResult as list
-->	{1.140238321076, 1.600286857702, 2.509178478658}
