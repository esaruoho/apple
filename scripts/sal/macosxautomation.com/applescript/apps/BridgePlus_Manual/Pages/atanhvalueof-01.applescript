use scripting additions
use framework "Foundation"
use script "BridgePlus"
load framework

set theResult to current application's SMSForder's atanhValueOf:(45 / 180 * pi)
ASify from theResult
-->	1.059306170823
theResult as real
-->	1.059306170823
set theResult to current application's SMSForder's atanhValueOf:{(30 / 180 * pi), (60 / 180 * pi), (90 / 180 * pi)}
ASify from theResult
-->	{0.581285011695, missing value, missing value}
theResult as list
-->	{0.581285011695, missing value, missing value}
