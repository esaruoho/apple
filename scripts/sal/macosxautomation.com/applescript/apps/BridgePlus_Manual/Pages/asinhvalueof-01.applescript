use scripting additions
use framework "Foundation"
use script "BridgePlus"
load framework

set theResult to current application's SMSForder's asinhValueOf:(45 / 180 * pi)
ASify from theResult
-->	0.721225488727
theResult as real
-->	0.721225488727
set theResult to current application's SMSForder's asinhValueOf:{(30 / 180 * pi), (60 / 180 * pi), (90 / 180 * pi)}
ASify from theResult
-->	{0.502218985035, 0.914356655393, 1.233403117511}
theResult as list
-->	{0.502218985035, 0.914356655393, 1.233403117511}
