use scripting additions
use framework "Foundation"
use script "BridgePlus"
load framework

set theResult to current application's SMSForder's acosValueOf:(45 / 180 * pi)
ASify from theResult
-->	0.667457216028
theResult as real
-->	0.667457216028
set theResult to current application's SMSForder's acosValueOf:{(30 / 180 * pi), (60 / 180 * pi), (90 / 180 * pi)}
ASify from theResult
-->	{1.019726743695, missing value, missing value}
theResult as list
-->	{1.019726743695, missing value, missing value}
